#!/usr/bin/env python3
"""Host-side human interface for the Jane QEMU prototype."""

import os
import math
import queue
import re
import shlex
import shutil
import subprocess
import tempfile
import threading
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, scrolledtext


ANSI_ESCAPE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\))")
REPO_ROOT = Path(__file__).resolve().parents[1]
QEMU_SCRIPT = REPO_ROOT / "build" / "run-qemu.sh"
VISUAL_ASSET_ROOT = REPO_ROOT / "assets" / "visual"
JANE_ICON = VISUAL_ASSET_ROOT / "branding" / "jane-ion-icon.png"

COLORS = {
    "void": "#020408",
    "black": "#03070d",
    "panel": "#07111b",
    "panel_2": "#0a1824",
    "line": "#12415e",
    "line_hot": "#27dfff",
    "blue": "#18a8ff",
    "cyan": "#5cecff",
    "white": "#f7fbff",
    "muted": "#8ea8ba",
    "silver": "#cbd8e6",
    "warning": "#ffbe4d",
    "success": "#68f5d1",
}

STATE_ACCENTS = {
    "STARTUP": COLORS["cyan"],
    "IDLE": "#4dbfff",
    "LISTENING": "#73fbff",
    "THINKING": "#8da0ff",
    "PROCESSING": "#18a8ff",
    "EXECUTING": "#4ed7ff",
    "SPEAKING": "#62f6ff",
    "SUCCESS": COLORS["success"],
    "WARNING": COLORS["warning"],
}

TELEMETRY_LABELS = (
    "COGNITIVE CORE",
    "PERCEPTION",
    "PLANNING",
    "ACTION SYSTEM",
    "MEMORY BUS",
)


class JaneInterface:
    def __init__(self, root):
        self.root = root
        self.root.title("JANE ION")
        self.root.geometry("1180x760")
        self.root.minsize(920, 620)
        self.events = queue.Queue()
        self.process = None
        self.voice_enabled = tk.BooleanVar(value=True)
        self.status = tk.StringVar(value="Starting Jane in QEMU...")
        self.visual_state = tk.StringVar(value="STARTUP")
        self.animation_tick = 0
        self.app_icon = None
        self.header_icon = None

        self._build_widgets()
        self._start_qemu()
        self.root.after(50, self._drain_events)
        self.root.after(80, self._animate_visuals)
        self.root.protocol("WM_DELETE_WINDOW", self.close)

    def _build_widgets(self):
        self.root.configure(bg=COLORS["void"])
        self._load_visual_assets()
        header = tk.Frame(self.root, bg=COLORS["void"], padx=18, pady=14)
        header.pack(fill=tk.X)
        brand = tk.Frame(header, bg=COLORS["void"])
        brand.pack(side=tk.LEFT)
        if self.header_icon is not None:
            tk.Label(brand, image=self.header_icon, bg=COLORS["void"]).pack(side=tk.LEFT, padx=(0, 12))
        brand_text = tk.Frame(brand, bg=COLORS["void"])
        brand_text.pack(side=tk.LEFT)
        tk.Label(
            brand_text,
            text="JANE ION",
            bg=COLORS["void"],
            fg=COLORS["white"],
            font=("DejaVu Sans", 22, "bold"),
        ).pack(anchor=tk.W)
        tk.Label(
            brand_text,
            text="THINK  /  PLAN  /  ACT",
            bg=COLORS["void"],
            fg=COLORS["cyan"],
            font=("DejaVu Sans", 8),
        ).pack(anchor=tk.W)
        status_shell = tk.Frame(header, bg=COLORS["void"])
        status_shell.pack(side=tk.RIGHT)
        tk.Label(
            status_shell,
            textvariable=self.visual_state,
            bg=COLORS["void"],
            fg=COLORS["cyan"],
            font=("DejaVu Sans", 9, "bold"),
        ).pack(anchor=tk.E)
        tk.Label(
            status_shell,
            textvariable=self.status,
            bg=COLORS["void"],
            fg=COLORS["muted"],
            font=("DejaVu Sans", 10),
        ).pack(anchor=tk.E)

        shell = tk.Frame(self.root, bg=COLORS["void"], padx=18, pady=(0, 14))
        shell.pack(fill=tk.BOTH, expand=True)

        left_panel = tk.Frame(shell, bg=COLORS["panel"], highlightbackground=COLORS["line"], highlightthickness=1)
        left_panel.pack(side=tk.LEFT, fill=tk.Y, padx=(0, 12))
        self.core_canvas = tk.Canvas(left_panel, width=285, height=360, bg=COLORS["panel"], bd=0, highlightthickness=0)
        self.core_canvas.pack(fill=tk.BOTH, expand=True, padx=10, pady=(10, 4))
        self.state_list = tk.Frame(left_panel, bg=COLORS["panel"])
        self.state_list.pack(fill=tk.X, padx=14, pady=(0, 12))
        for label in ("IDLE", "LISTENING", "THINKING", "PROCESSING", "SPEAKING", "EXECUTING", "SUCCESS", "WARNING"):
            row = tk.Frame(self.state_list, bg=COLORS["panel"])
            row.pack(fill=tk.X, pady=2)
            tk.Label(row, text="o", bg=COLORS["panel"], fg=STATE_ACCENTS.get(label, COLORS["cyan"]), font=("DejaVu Sans", 10)).pack(side=tk.LEFT)
            tk.Label(row, text=label, bg=COLORS["panel"], fg=COLORS["muted"], font=("DejaVu Sans", 8)).pack(side=tk.LEFT, padx=(8, 0))

        center_panel = tk.Frame(shell, bg=COLORS["panel"], highlightbackground=COLORS["line"], highlightthickness=1)
        center_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 12))
        terminal_header = tk.Frame(center_panel, bg=COLORS["panel"], padx=14, pady=10)
        terminal_header.pack(fill=tk.X)
        tk.Label(
            terminal_header,
            text="JANE TERMINAL",
            bg=COLORS["panel"],
            fg=COLORS["silver"],
            font=("DejaVu Sans", 10, "bold"),
        ).pack(side=tk.LEFT)
        tk.Label(
            terminal_header,
            text="SERIAL / QEMU",
            bg=COLORS["panel"],
            fg=COLORS["cyan"],
            font=("DejaVu Sans", 8),
        ).pack(side=tk.RIGHT)

        self.transcript = scrolledtext.ScrolledText(
            center_panel,
            bg=COLORS["black"],
            fg="#eaf6ff",
            insertbackground=COLORS["cyan"],
            relief=tk.FLAT,
            wrap=tk.WORD,
            padx=16,
            pady=14,
            font=("DejaVu Sans Mono", 10),
        )
        self.transcript.pack(fill=tk.BOTH, expand=True, padx=12, pady=(0, 12))
        self.transcript.configure(state=tk.DISABLED)

        controls = tk.Frame(center_panel, bg=COLORS["panel"], padx=12, pady=(0, 12))
        controls.pack(fill=tk.X)
        self.entry = tk.Entry(
            controls,
            bg=COLORS["panel_2"],
            fg="#f5f7fa",
            insertbackground=COLORS["cyan"],
            relief=tk.FLAT,
            font=("DejaVu Sans", 11),
        )
        self.entry.pack(side=tk.LEFT, fill=tk.X, expand=True, ipady=9)
        self.entry.bind("<Return>", self._send_from_entry)
        tk.Button(
            controls,
            text="Send",
            command=self._send_from_entry,
            bg=COLORS["blue"],
            fg="#03101a",
            activebackground=COLORS["cyan"],
            relief=tk.FLAT,
            padx=16,
        ).pack(side=tk.LEFT, padx=(8, 0), ipady=5)
        tk.Button(
            controls,
            text="Listen",
            command=self._listen,
            bg="#123a56",
            fg="#ffffff",
            activebackground="#1d6d92",
            relief=tk.FLAT,
            padx=14,
        ).pack(side=tk.LEFT, padx=(8, 0), ipady=5)
        tk.Checkbutton(
            controls,
            text="Speak",
            variable=self.voice_enabled,
            bg=COLORS["panel"],
            fg="#e6edf3",
            activebackground=COLORS["panel"],
            activeforeground="#ffffff",
            selectcolor="#0b1823",
        ).pack(side=tk.LEFT, padx=(10, 0))

        right_panel = tk.Frame(shell, bg=COLORS["panel"], highlightbackground=COLORS["line"], highlightthickness=1)
        right_panel.pack(side=tk.RIGHT, fill=tk.Y)
        self.presence_canvas = tk.Canvas(right_panel, width=260, height=430, bg=COLORS["panel"], bd=0, highlightthickness=0)
        self.presence_canvas.pack(fill=tk.BOTH, expand=True, padx=10, pady=(10, 6))
        telemetry = tk.Frame(right_panel, bg=COLORS["panel"])
        telemetry.pack(fill=tk.X, padx=14, pady=(0, 14))
        tk.Label(
            telemetry,
            text="SYSTEM VISUALS",
            bg=COLORS["panel"],
            fg=COLORS["silver"],
            font=("DejaVu Sans", 9, "bold"),
        ).pack(anchor=tk.W, pady=(0, 6))
        for label in TELEMETRY_LABELS:
            row = tk.Frame(telemetry, bg=COLORS["panel"])
            row.pack(fill=tk.X, pady=2)
            tk.Label(row, text=label, bg=COLORS["panel"], fg=COLORS["muted"], font=("DejaVu Sans", 8)).pack(side=tk.LEFT)
            tk.Label(row, text="ONLINE", bg=COLORS["panel"], fg=COLORS["cyan"], font=("DejaVu Sans", 8)).pack(side=tk.RIGHT)

    def _set_visual_state(self, state, status=None):
        self.visual_state.set(state)
        if status is not None:
            self.status.set(status)

    def _animate_visuals(self):
        self.animation_tick += 1
        self._draw_core()
        self._draw_presence()
        self.root.after(80, self._animate_visuals)

    def _draw_core(self):
        canvas = self.core_canvas
        canvas.delete("all")
        width = max(canvas.winfo_width(), 285)
        height = max(canvas.winfo_height(), 360)
        cx = width / 2
        cy = height * 0.44
        state = self.visual_state.get()
        accent = STATE_ACCENTS.get(state, COLORS["cyan"])
        pulse = math.sin(self.animation_tick / 7) * 6
        activity = 1.0
        if state in ("LISTENING", "SPEAKING"):
            activity = 1.35
        elif state in ("THINKING", "PROCESSING", "EXECUTING", "STARTUP"):
            activity = 1.2
        elif state == "SUCCESS":
            activity = 1.45
        elif state == "WARNING":
            activity = 1.25

        self._draw_panel_grid(canvas, width, height)
        canvas.create_text(14, 18, anchor=tk.W, text="AI CORE", fill=COLORS["silver"], font=("DejaVu Sans", 10, "bold"))
        canvas.create_text(width - 14, 18, anchor=tk.E, text=state, fill=accent, font=("DejaVu Sans", 8, "bold"))

        for i, radius in enumerate((128, 102, 76, 48)):
            dash = (12 + i * 3, 12)
            extent = 290 if i % 2 == 0 else -270
            start = (self.animation_tick * (1.6 + i * 0.55) + i * 42) % 360
            canvas.create_arc(
                cx - radius,
                cy - radius,
                cx + radius,
                cy + radius,
                start=start,
                extent=extent,
                style=tk.ARC,
                outline=accent if i < 2 else COLORS["line_hot"],
                width=max(1, 4 - i),
                dash=dash,
            )

        for angle in range(0, 360, 45):
            rad = math.radians(angle + self.animation_tick)
            inner = 62
            outer = 137
            canvas.create_line(
                cx + math.cos(rad) * inner,
                cy + math.sin(rad) * inner,
                cx + math.cos(rad) * outer,
                cy + math.sin(rad) * outer,
                fill=COLORS["line"],
            )

        glow_radius = 32 + pulse * activity
        canvas.create_oval(
            cx - glow_radius * 2.2,
            cy - glow_radius * 2.2,
            cx + glow_radius * 2.2,
            cy + glow_radius * 2.2,
            fill="",
            outline=accent,
            width=1,
        )
        canvas.create_oval(
            cx - glow_radius,
            cy - glow_radius,
            cx + glow_radius,
            cy + glow_radius,
            fill="#082033",
            outline=COLORS["cyan"],
            width=2,
        )
        self._draw_j_mark(canvas, cx, cy, accent)

        if state in ("LISTENING", "SPEAKING"):
            self._draw_waveform(canvas, cx, cy + 148, width - 42, accent)
        elif state in ("THINKING", "PROCESSING", "EXECUTING", "STARTUP"):
            self._draw_data_stream(canvas, cx, cy + 144, width - 42, accent)
        elif state == "SUCCESS":
            canvas.create_text(cx, cy + 150, text="ACTION COMPLETE", fill=COLORS["success"], font=("DejaVu Sans", 9, "bold"))
        elif state == "WARNING":
            canvas.create_text(cx, cy + 150, text="ATTENTION REQUIRED", fill=COLORS["warning"], font=("DejaVu Sans", 9, "bold"))
        else:
            canvas.create_text(cx, cy + 150, text="LOW-ACTIVITY AWARENESS FIELD", fill=COLORS["muted"], font=("DejaVu Sans", 8))

    def _draw_presence(self):
        canvas = self.presence_canvas
        canvas.delete("all")
        width = max(canvas.winfo_width(), 260)
        height = max(canvas.winfo_height(), 430)
        state = self.visual_state.get()
        accent = STATE_ACCENTS.get(state, COLORS["cyan"])
        self._draw_panel_grid(canvas, width, height)
        canvas.create_text(14, 18, anchor=tk.W, text="AI PRESENCE", fill=COLORS["silver"], font=("DejaVu Sans", 10, "bold"))
        canvas.create_text(width - 14, 18, anchor=tk.E, text="JANE", fill=accent, font=("DejaVu Sans", 8, "bold"))

        cx = width * 0.52
        top = 64
        breathing = math.sin(self.animation_tick / 10) * 4
        aura = 94 + breathing
        canvas.create_oval(cx - aura, top + 28, cx + aura, top + 28 + aura * 2, outline=COLORS["line"], width=1)
        canvas.create_oval(cx - aura * 0.7, top + 58, cx + aura * 0.7, top + 58 + aura * 1.4, outline=accent, width=1)

        profile = (
            cx - 12, top + 14,
            cx - 48, top + 34,
            cx - 61, top + 82,
            cx - 45, top + 126,
            cx - 20, top + 152,
            cx + 24, top + 176,
            cx + 44, top + 222,
            cx + 62, top + 314,
        )
        canvas.create_line(profile, fill=COLORS["silver"], width=3, smooth=True)
        canvas.create_line(
            cx - 18, top + 60,
            cx + 24, top + 72,
            cx + 48, top + 112,
            cx + 34, top + 156,
            fill=accent,
            width=2,
            smooth=True,
        )
        canvas.create_line(cx - 38, top + 105, cx + 22, top + 98, cx + 52, top + 84, fill=COLORS["white"], width=2, smooth=True)
        canvas.create_oval(cx - 4, top + 91, cx + 9, top + 104, fill=accent, outline="")

        for i in range(18):
            angle = (self.animation_tick * 2 + i * 37) % 360
            rad = math.radians(angle)
            px = cx + math.cos(rad) * (86 + (i % 4) * 10)
            py = top + 180 + math.sin(rad) * (122 + (i % 3) * 9)
            size = 2 if i % 3 else 3
            canvas.create_oval(px - size, py - size, px + size, py + size, fill=accent, outline="")

        canvas.create_text(
            width / 2,
            height - 74,
            text="COGNITIVE CORE / PRESENCE FIELD",
            fill=COLORS["muted"],
            font=("DejaVu Sans", 8),
        )
        canvas.create_line(24, height - 50, width - 24, height - 50, fill=COLORS["line"])
        canvas.create_text(width / 2, height - 28, text="ONLINE", fill=accent, font=("DejaVu Sans", 14, "bold"))

    def _draw_panel_grid(self, canvas, width, height):
        for x in range(40, int(width), 40):
            canvas.create_line(x, 0, x, height, fill="#071a26")
        for y in range(40, int(height), 40):
            canvas.create_line(0, y, width, y, fill="#071a26")
        canvas.create_rectangle(2, 2, width - 3, height - 3, outline=COLORS["line"])

    def _draw_j_mark(self, canvas, cx, cy, accent):
        canvas.create_line(cx + 26, cy - 46, cx + 26, cy + 32, cx + 5, cy + 61, cx - 34, cy + 54, cx - 50, cy + 28, fill=COLORS["white"], width=9, smooth=True)
        canvas.create_line(cx + 24, cy - 46, cx - 8, cy - 26, cx - 24, cy + 14, cx - 14, cy + 43, fill=accent, width=4, smooth=True)
        canvas.create_arc(cx - 58, cy - 46, cx + 48, cy + 56, start=286, extent=122, outline=accent, width=2)
        canvas.create_line(cx - 18, cy - 3, cx + 20, cy - 9, fill=COLORS["silver"], width=2)
        canvas.create_oval(cx + 1, cy - 16, cx + 13, cy - 4, fill=accent, outline="")

    def _draw_waveform(self, canvas, cx, y, width, accent):
        left = cx - width / 2
        points = []
        for i in range(48):
            x = left + i * width / 47
            amp = math.sin((self.animation_tick + i * 3) / 4) * (8 + (i % 5) * 2)
            points.append((x, y + amp))
        for (x1, y1), (x2, y2) in zip(points, points[1:]):
            canvas.create_line(x1, y1, x2, y2, fill=accent, width=2)
        canvas.create_text(cx, y + 26, text="VOICE ENERGY RESPONSE", fill=COLORS["muted"], font=("DejaVu Sans", 8))

    def _draw_data_stream(self, canvas, cx, y, width, accent):
        left = cx - width / 2
        for i in range(5):
            offset = (self.animation_tick * (3 + i) + i * 44) % width
            canvas.create_line(left + offset - 44, y + i * 9, left + offset + 44, y + i * 9, fill=accent, width=2)
        canvas.create_text(cx, y + 60, text="SCANNING / PLANNING / ACTION READY", fill=COLORS["muted"], font=("DejaVu Sans", 8))

    def _load_visual_assets(self):
        if not JANE_ICON.is_file():
            return
        try:
            self.app_icon = tk.PhotoImage(file=str(JANE_ICON))
            self.root.iconphoto(True, self.app_icon)
            self.header_icon = self.app_icon.subsample(8, 8)
        except tk.TclError:
            self.app_icon = None
            self.header_icon = None

    def _start_qemu(self):
        if not QEMU_SCRIPT.is_file():
            self._set_visual_state("WARNING", "Interface error")
            self._append("Interface error: build/run-qemu.sh is missing.\n")
            return
        try:
            self.process = subprocess.Popen(
                [str(QEMU_SCRIPT)],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                errors="replace",
            )
        except OSError as error:
            self._set_visual_state("WARNING", "Interface error")
            self._append(f"Interface error: could not start QEMU: {error}\n")
            return
        threading.Thread(target=self._read_qemu, daemon=True).start()

    def _read_qemu(self):
        assert self.process is not None
        assert self.process.stdout is not None
        for line in self.process.stdout:
            self.events.put(("output", line))
        self.events.put(("closed", self.process.returncode))

    def _drain_events(self):
        try:
            while True:
                event, value = self.events.get_nowait()
                if event == "output":
                    self._handle_output(value)
                elif event == "closed":
                    self._set_visual_state("WARNING", "Jane stopped")
        except queue.Empty:
            pass
        self.root.after(50, self._drain_events)

    def _handle_output(self, value):
        clean = ANSI_ESCAPE.sub("", value).replace("\r", "")
        if not clean:
            return
        self._append(clean)
        if "Jane terminal ready" in clean:
            self._set_visual_state("IDLE", "Ready")
        elif "RESULT:" in clean:
            self._set_visual_state("SUCCESS", "Action complete")
            self.root.after(1600, lambda: self._set_visual_state("IDLE", "Ready"))
        elif "PERMISSION:" in clean:
            self._set_visual_state("EXECUTING", "Permission check")
        elif "error" in clean.lower() or "failed" in clean.lower():
            self._set_visual_state("WARNING", "Attention required")
        if self.voice_enabled.get() and self._should_speak(clean):
            self._speak(clean)

    def _should_speak(self, value):
        return any(marker in value for marker in ("RESULT:", "PERMISSION:", "Jane v0.1:"))

    def _append(self, value):
        self.transcript.configure(state=tk.NORMAL)
        self.transcript.insert(tk.END, value)
        self.transcript.see(tk.END)
        self.transcript.configure(state=tk.DISABLED)

    def _send_from_entry(self, _event=None):
        request = self.entry.get().strip()
        if not request:
            return
        self.entry.delete(0, tk.END)
        self._send(request)

    def _send(self, request):
        if self.process is None or self.process.poll() is not None:
            messagebox.showerror("Jane is not running", "Start the interface after building the OS image.")
            return
        assert self.process.stdin is not None
        try:
            self._set_visual_state("THINKING", "Planning request")
            self.process.stdin.write(request + "\n")
            self.process.stdin.flush()
        except OSError as error:
            self._set_visual_state("WARNING", "Interface error")
            self._append(f"Interface error: {error}\n")

    def _listen(self):
        stt_command = os.environ.get("JANE_STT_COMMAND", "").strip()
        if not stt_command and shutil.which("pocketsphinx_continuous"):
            stt_command = "pocketsphinx_continuous -logfn /dev/null -infile"
        if not stt_command:
            self._set_visual_state("WARNING", "Voice input unavailable")
            messagebox.showinfo(
                "Voice input is not configured",
                "Set JANE_STT_COMMAND to an STT command. It receives a WAV file path and must print the transcript.\n\nVoice replies are already enabled through espeak-ng.",
            )
            return
        threading.Thread(target=self._record_and_transcribe, args=(stt_command,), daemon=True).start()
        self._set_visual_state("LISTENING", "Listening...")

    def _record_and_transcribe(self, stt_command):
        audio_path = None
        sent_transcript = False
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as audio:
                audio_path = audio.name
            recorder = shutil.which("arecord") or shutil.which("parecord")
            if not recorder:
                raise RuntimeError("arecord or parec is required for microphone input")
            record_args = [recorder, "-q", "-f", "S16_LE", "-r", "16000", "-c", "1", audio_path]
            subprocess.run(record_args, check=True, timeout=15)
            command = shlex.split(stt_command) + [audio_path]
            result = subprocess.run(command, check=True, capture_output=True, text=True, timeout=60)
            transcript = result.stdout.strip()
            if transcript:
                sent_transcript = True
                self.root.after(0, lambda: self._set_visual_state("THINKING", "Planning request"))
                self.root.after(0, lambda: self._send(transcript))
            else:
                raise RuntimeError("the STT command returned no text")
        except (OSError, RuntimeError, subprocess.SubprocessError) as error:
            self.root.after(0, lambda: self._set_visual_state("WARNING", "Voice input failed"))
            self.root.after(0, lambda: messagebox.showerror("Voice input failed", str(error)))
        finally:
            if audio_path:
                Path(audio_path).unlink(missing_ok=True)
            if not sent_transcript:
                self.root.after(0, lambda: self._set_visual_state("IDLE", "Ready"))

    def _speak(self, value):
        speaker = shutil.which("espeak-ng")
        if speaker:
            self._set_visual_state("SPEAKING", "Speaking")
            text = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", value).strip()
            subprocess.Popen([speaker, "-s", "155", text], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.root.after(2400, lambda: self._set_visual_state("IDLE", "Ready"))

    def close(self):
        if self.process and self.process.poll() is None:
            try:
                assert self.process.stdin is not None
                self.process.stdin.write("exit\n")
                self.process.stdin.flush()
                self.process.wait(timeout=3)
            except (OSError, subprocess.TimeoutExpired):
                self.process.terminate()
        self.root.destroy()


def check():
    missing = []
    if not QEMU_SCRIPT.is_file():
        missing.append(str(QEMU_SCRIPT))
    if not shutil.which("qemu-system-x86_64"):
        missing.append("qemu-system-x86_64")
    if not shutil.which("espeak-ng"):
        missing.append("espeak-ng (optional for typed mode, required for spoken replies)")
    if not shutil.which("pocketsphinx_continuous"):
        missing.append("pocketsphinx_continuous (required for default voice input)")
    if missing:
        print("missing: " + ", ".join(missing))
        return 1
    print("PASS: Jane human interface prerequisites")
    return 0


def main():
    if len(os.sys.argv) == 2 and os.sys.argv[1] == "--check":
        return check()
    root = tk.Tk()
    JaneInterface(root)
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
