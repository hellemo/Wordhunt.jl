# Wordhunt

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

Create wordhunt games using integer programming! Based on original model implemented in Mosel, courtesy of Truls Flatberg.

## Example

```julia
using Wordhunt

wordhunt(["ALI", "ADA", "MILO"]; D=[:S, :E, :SE], gridsize=4)
```