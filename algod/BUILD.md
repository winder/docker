# Build details

Image is built using two stages. In the first stage, binaries are generated with the `install.sh` script. Resulting binaries are copied into the second stage for final packaging.

## Build Arguments

Binaries are generated using the following build arguments.
| Argument | Description |
| -------- | ----------- |
| CHANNEL  | Download latest binaries for a given release channel. |
| URL      | Git URL to download sources from. |
| BRANCH   | Git branch to checkout. |
| SHA      | Git commit hash to checkout. |
