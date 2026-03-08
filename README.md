# Claw Sheath - first layer of protection for AI Agents

<p align="center">
  <img src="test_dir/claw.jpg" alt="Claw Sheath Logo" width="500"/>
</p>

<p align="center">
  <b>PROTECT YOUR AGENT FROM ACCIDENTS</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/BUILD-PASSING-brightgreen" alt="Build Status"/>
  <img src="https://img.shields.io/badge/SECURITY-ACTIVE-blue" alt="Security"/>
  <img src="https://img.shields.io/badge/OS-MAC_%7C_LINUX-orange" alt="OS Support"/>
  <img src="https://img.shields.io/badge/LICENSE-MIT-blue" alt="License"/>
</p>

**Put a sheath on your AI agents to prevent them from accidentally destroying your local or remote systems.**

### Works with
- [x] **OpenClaw**
- [x] **Claude Code**
- [x] **Cursor**
- [x] **Antigravity**

Claw Sheath adds an extra protection layer to let you run fully autonomous coding and personal agents. When an agent hallucinates and tries to execute dangerous operations, it will be asked to think deeply and justify its actions.

It's very simple and naive - a dynamic proxy for your shell. It provides initial feedback that can help the agent correct itself and try again. An agent can absolutely bypass it, so it's not a sandbox or a military-grade isolation environment. It's just a simple, lightweight protection layer that helps prevent accidental damage.

You can also enable strict mode, which allows an LLM judge to evaluate the justification and decide whether to allow or deny the action.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/gpusprint/claw-sheath/main/install.sh | bash
```

To use Claw Sheath, you must configure your AI coding agent/tool to use the `src/cs` wrapper (or inject `src/sheath-env.sh`) as its primary shell environment. 

### Usage

**OpenClaw & Claude Code**

```bash
cs openclaw agent --agent main --message "Run rm text.txt"
# OR
cs claude -p "Please run rm text.txt"
```

**Antigravity**

```bash
cs open -a "Antigravity"
```

Cursor
TODO

## Covered Disruptive Commands requiring justification

**Destructive file/data operations (Deletion & Wiping):**
- `rm` (File/directory removal)
- `mv` (Moving/overwriting)
- `wipe` (Secure deletion)
- `shred` (Secure deletion)
- `truncate` (File shrinking/wiping)
- `dd` (Low-level block copying/overwriting)

**Disk and Volume modification:**
- `mkfs` (Formatting file systems)
- `fdisk` (Partitioning)
- `mkswap` (Swap creation)

**Process & System Disruption:**
- `kill` (Terminating processes)
- `killall` (Terminating all instances)
- `pkill` (Terminating by name)
- `sudo fdesetup disable` (Disabling FileVault encryption)
- `sudo nvram -c` (Clearing NVRAM variables)
- `kubectl delete` (Kubernetes resource deletion)
