# GPTrace Evaluation

This documentation explains how to evaluate GPTrace with data sources that
you generated yourself.

## Requirements

- Python 3 with pip and venv

## Steps

### Preparation

- If not done already, follow the steps

  - [Get Targets](/GENERATE_DATA_SOURCES.md#get-targets)
  - [Get Crashing Inputs](/GENERATE_DATA_SOURCES.md#get-crashing-inputs)
  - [Build Docker Images](/GENERATE_DATA_SOURCES.md#build-docker-images)
  - [Start Docker Containers and Collect Data Sources](/GENERATE_DATA_SOURCES.md#start-docker-containers-and-collect-data-sources)

  in [GENERATE_DATA_SOURCES.md](/GENERATE_DATA_SOURCES.md) as well as

  - [Preparation](/README.md#preparation)

  in [README.md](/README.md)

### Start Docker Containers and Evaluate GPTrace

  ```bash
  scripts/all.sh gptrace
  ```

- The script will tell GPTrace to use OpenAI's embedding model.
  Further information is contained in the README of GPTrace.
- The raw results will be stored in
  `reproduce/generate_data_sources/targets/${TARGET}/out/raw_gptrace_results`
- The results can be read from the logfile
  `reproduce/generate_data_sources/targets/${TARGET}/out/gptrace.log`
