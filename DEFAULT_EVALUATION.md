# DeFault Evaluation

This documentation explains how to evaluate our rudimentary DeFault
implementation with data sources that you generated yourself.
DeFault was developed in the following paper:

> Xing Zhang, Jiongyi Chen, Chao Feng, Ruilin Li, Wenrui Diao, Kehuan Zhang,
> Jing Lei, and Chaojing Tang. 2022.
> DeFault: mutual information-based crash triage for massive crashes.
> In Proceedings of the 44th International Conference on Software Engineering
> (ICSE '22). Association for Computing Machinery, New York, NY, USA, 635–646.
> <https://doi.org/10.1145/3510003.3512760>

## Requirements

- Docker

## Steps

### Preparation

- If not done already, follow the steps

  - [Get Targets](/GENERATE_DATA_SOURCES.md#get-targets)
  - [Get Crashing Inputs](/GENERATE_DATA_SOURCES.md#get-crashing-inputs)

  in [GENERATE_DATA_SOURCES.md](/GENERATE_DATA_SOURCES.md).

- The MoonLight targets are 32 bit.
  In order for Intel Pin to be able to correctly generate traces you might need
  to (temporarily) disable `vsyscall32`:
  ```bash
  echo 0 | sudo tee /proc/sys/abi/vsyscall32
  ```

### Build Docker Images

  ```bash
  scripts/all.sh build-default
  ```

- The resulting Docker images are tagged `default/${TARGET}`.
- Individual images can be built by running

  ```bash
  scripts/generated_data_sources/build.sh ${TARGET} default
  ```

### Start Docker Containers and Collect Execution Traces and DeFault Results

  ```bash
  scripts/all.sh default
  ```

- The execution traces will be stored in
  `reproduce/generate_data_sources/targets/${TARGET}/out/default/pin_traces`
- The results will be collected in
  `reproduce/generate_data_sources/targets/${TARGET}/out/default/summary`
- Potential errors can be read from the logfile
  `reproduce/generate_data_sources/targets/${TARGET}/out/default/pin.log`
