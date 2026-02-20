# Prototype Implementation of DeFault

This is a prototype implementation of the deduplication method of DeFault based on the
description in the [paper](https://dl.acm.org/doi/10.1145/3510003.3512760).

## Preparation

- If you already have [uv](https://github.com/astral-sh/uv) installed, skip this
  step.
  Otherwise, install it either on your host by following the steps from the
  official [documentation](https://docs.astral.sh/uv/) or in a Python virtual
  environment

  ```bash
  python -m venv gptrace/.venv
  source gptrace/.venv/bin/activate
  pip install uv
  ```

- Run `default`:

  ```bash
  uv run default --help
  ```

## Collect Traces

DeFault parses basic blocks of execution traces.
To collect those, download [Intel Pin](https://www.intel.com/content/www/us/en/developer/articles/tool/pin-a-dynamic-binary-instrumentation-tool.html) (we used version 3.31) and use the bbl_tracing script that is part of this repo
which outputs files in the appropriate format (see below).

```bash
path/to/pin-3.31/pin -t path/to/bbl_tracing/obj-intel64/bbl_tracing.so -o /path/to/output/file -- /path/to/binary --possible --arguments
```

Also make sure to disable ASLR:

```bash
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
```

To collect traces for the MoonLight targets (which are 32bit), set the following compatibility
config:

```bash
echo 0 | sudo tee /proc/sys/abi/vsyscall32
```

After generating the traces, reboot to reset the above settings (randomize_va_space to 2 and
vsyscall32 to 1).

## Running DeFault

Our DeFault implementation takes as input a set of files that contain in each line an address
and a number that specifies how often that address was encountered during the execution of the
binary:

```text
f7fd6fda 11
```

One address can occur multiple times in a file.
Use the script as follows

```bash
uv run default -c /path/to/crash_traces -n /path/to/non_crash_traces -o /path/to/output/dir
```

For instance, to deduplicate the example data

```bash
uv run default -c example_data/pdftotext_crashing -n example_data/pdftotext_non_crashing -o example_data/out
```

Note that the phase `Collecting basic blocks from traces` becomes faster with further progress.
It still takes some time, however.
Since the execution traces that DeFault requires are so large, we cannot provide them here.
