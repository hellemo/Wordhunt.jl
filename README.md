# Wordhunt

Create wordhunt games using integer programming! Based on original model implemented in Mosel, courtesy of Truls Flatberg.

## Example

```julia
using Wordhunt
wordhunt(["ALI","ADA","MILO"]; D=[:S,:E,:SE], gridsize=4)
```