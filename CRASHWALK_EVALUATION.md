# Crashwalk Evaluation

This documentation explains how to evaluate Crashwalk both with data sources
that we provide and with data sources that you generated yourself.

## Requirements

- Docker

## Steps to Evaluate Crashwalk with Our Data Sources

### Preparation

- If not done already, follow the steps

  - [Get Targets](/GENERATE_DATA_SOURCES.md#get-targets)
  - [Build Docker Images](/GENERATE_DATA_SOURCES.md#build-docker-images)

  in [GENERATE_DATA_SOURCES.md](/GENERATE_DATA_SOURCES.md) as well as

  - [Get Data Sources](/README.md#get-data-sources)

  in [README.md](/README.md).

### Start Docker Containers and Evaluate Crashwalk

  ```bash
  scripts/all.sh crashwalk_provided
  ```

- The results will be stored in
  `reproduce/evaluation/results/crashwalk/${TARGET}/results`
- Potential errors can be read from the logfile
  `reproduce/evaluation/results/crashwalk/${TARGET}/log`

## Steps to Evaluate Crashwalk with Your Own Data Sources

### Preparation

- If not done already, follow the steps

  - [Get Targets](/GENERATE_DATA_SOURCES.md#get-targets)
  - [Get Crashing Inputs](/GENERATE_DATA_SOURCES.md#get-crashing-inputs)
  - [Build Docker Images](/GENERATE_DATA_SOURCES.md#build-docker-images)

  in [GENERATE_DATA_SOURCES.md](/GENERATE_DATA_SOURCES.md).

### Start Docker Containers and Evaluate Crashwalk

  ```bash
  scripts/all.sh crashwalk
  ```

- The databases will be stored in
  `reproduce/generate_data_sources/targets/${TARGET}/out/crashwalk.db`
- The results will be collected in
  `reproduce/generate_data_sources/targets/${TARGET}/out/crashwalk_results`
- Potential errors can be read from the logfile
  `reproduce/generate_data_sources/targets/${TARGET}/out/crashwalk.log`
