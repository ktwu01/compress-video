# Project: Adapt Study Vlog Builder for WSL (Windows Subsystem for Linux)

## Background and Motivation
The user is setting up the environment in WSL to run `wsl_builder.sh`. They attempted to install `ffmpeg` using `sudo apt install ffmpeg` but received an error stating the package could not be found, with a suggestion to use `snap`. This usually happens when the package lists are outdated or the repository doesn't contain `ffmpeg` (common in some minimal WSL distros or older Ubuntu versions without universe repo enabled).

## Key Challenges and Analysis
- **Package Manager Issues**: `apt` cannot find `ffmpeg`.
- **Potential Causes**:
  1.  `apt update` hasn't been run recently.
  2.  The distribution is missing the 'universe' repository (Ubuntu).
  3.  The user is on a distribution that doesn't package ffmpeg directly (less likely for standard Ubuntu).
- **Snap in WSL**: While `snap install ffmpeg` is suggested, Snap support in WSL can sometimes be tricky or require systemd support to be enabled. Using `apt` is generally preferred and more robust for simple CLI tools if possible.
- **Action Plan**:
  1.  Recommend running `sudo apt update` first.
  2.  Recommend installing via `snap` if `apt` still fails, or enable the universe repository.

## High-level Task Breakdown
1. [x] **Plan & Path Mapping** (Planner) - Completed.
2. [x] **Modify Script** (Executor) - Completed.
3. [ ] **Environment Troubleshooting** (Executor)
   - Guide user to update `apt` cache.
   - If that fails, guide user to use `snap` or enable repositories.

## Project Status Board
- [x] Update `study_vlog_builder.sh` to use `/mnt/c` paths.
- [x] Fix font paths for WSL.
- [ ] Install `ffmpeg` in WSL (In Progress - User blocked).

## Executor's Feedback or Assistance Requests
- The user pasted terminal output showing `E: Unable to locate package ffmpeg`.
- I need to guide them to update their package lists.
