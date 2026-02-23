# Generate Data Sources

This documentation explains how to generate fresh stack traces, ASan reports and
embeddings for the targets and crashing inputs that we used in our evaluation.

## Requirements

- Docker

## Steps

### Get Targets

  ```bash
  scripts/generate_data_sources/get_targets.sh
  ```

- This downloads the targets from [Magma](https://hexhive.epfl.ch/magma/) and
  [MoonLight](https://arxiv.org/pdf/1905.13055v1.pdf).
- Afterwards, make sure to install the 
  [Magma dependencies](https://hexhive.epfl.ch/magma/docs/getting-started.html):

  ```bash
  sudo apt update && sudo apt install -y util-linux inotify-tools docker.io git
  ```

### Get Crashing Inputs

  ```bash
  scripts/generate_data_sources/get_inputs.sh
  ```

- This downloads a ground truth benchmark of
  [crashing inputs](https://github.com/HexHive/PoCalypse)
  that we used in our evaluation.
  This benchmark was created by the authors of the Igor paper:
  > Zhiyuan Jiang, Xiyue Jiang, Ahmad Hazimeh, Chaojing Tang, Chao Zhang,
  > and Mathias Payer. 2021. Igor: Crash Deduplication Through Root-Cause
  > Clustering. In Proceedings of the 2021 ACM SIGSAC Conference on Computer
  > and Communications Security (CCS ’21), November 15–19, 2021, Virtual Event,
  > Republic of Korea. ACM, New York, NY, USA, 19 pages.
  > <https://doi.org/10.1145/3460120.3485364>
  
  Note that, as we explain in section 4 of our paper, we made small adjustments
  to the labeling of the crashing inputs by restructuring the file tree of the
  benchmark.
  These changes are based on the mappings from bug IDs to CVE IDs in Table A1
  in the [Magma paper](https://hexhive.epfl.ch/publications/files/21SIGMETRICS.pdf#appendix.A)
  and Table 4 in the [MoonLight paper](https://arxiv.org/pdf/1905.13055#subsection.5.2)
  as well as Table 5 in the
  [Igor paper](https://hexhive.epfl.ch/publications/files/21CCS.pdf#appendix.D)
  which shows which bug IDs share the same underlying vulnerabilities.
  They are summarized in the following table, together with an overview of
  which bugs we were unable to reproduce:

  | Target             | Bug ID               | CVE ID     | Comment                                                                    |
  | ------------------ | -------------------- | ---------- | -------------------------------------------------------------------------- |
  | freetype__char2svg | poc_A_raw            | 2014-9663  | Same as poc_D_raw and poc_G_raw                                            |
  |                    | poc_B_raw            | 2015-9290  | Same as poc_H_raw                                                          |
  |                    | poc_D_raw            | 2014-9669  | Same as poc_A_raw and poc_G_raw                                            |
  |                    | poc_G_raw            | 2015-9383  | Same as poc_A_raw and poc_D_raw                                            |
  |                    | poc_H_raw            | 2015-9381  | Same as poc_B_raw                                                          |
  | libtiff__tiff2pdf  | poc_D_raw            | 2018-5784  | Could not reproduce                                                        |
  | libtiff__tiffcp    | poc_AAH015_raw       | 2016-10270 | Could not reproduce                                                        |
  |                    | poc_CVE201610269_raw | 2016-10269 | Only contains duplicate inputs present in poc_AAH013_raw or poc_AAH014_raw |
  | libxml2__xmllint   | poc_C_raw            | 2015-5312  | Could not reproduce                                                        |
  |                    | poc_I_raw            | 2015-7499  | Same as poc_J_raw                                                          |
  |                    | poc_J_raw            | 2015-7498  | Same as poc_I_raw                                                          |
  | openssl__x509      | poc_AAH055_raw       | 2016-2108  | Could not reproduce                                                        |
  | soxmp3__sox        | poc_E_raw            | 2019-8354  | Same as poc_F_raw                                                          |
  |                    | poc_F_raw            | 2019-8356  | Same as poc_E_raw                                                          |
  | soxwav__sox        | poc_C_raw            | 2019-8354  | Same as poc_D_raw                                                          |
  |                    | poc_D_raw            | 2019-8356  | Same as poc_C_raw                                                          |
  
- This script also downloads a set of non-crashing inputs from our
  [Zenodo repository](https://zenodo.org/records/18708473) that is needed for the reproduction
  of the evaluation of our rudimentary DeFault implementation.
  See [DEFAULT_EVALUATION.md](DEFAULT_EVALUATION.md) for more information.

### Build Docker Images

  ```bash
  scripts/all.sh build
  ```

- The resulting Docker images are tagged `gptrace/${TARGET}`.
- Individual images can be built by running

  ```bash
  scripts/generated_data_sources/build.sh ${TARGET}
  ```

### Start Docker Containers and Collect Data Sources

- To generate data sources that GPTrace (and the other deduplication tools)
  can use, you need to (temporarily) disable ASLR:
  ```bash
  echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
  ```
  Afterwards, start collecting data sources using the Docker images by running
  the following command:

  ```bash
  scripts/all.sh collect
  ```

- To change the number of parallel workers, set the variable
  `OVERWRITE_WORKERS` in `scripts/all.sh`.
- The traces and ASan logs will be stored in
  `reproduce/generate_data_sources/targets/${TARGET}/out`
  (though they will only appear there once all inputs have been processed)
