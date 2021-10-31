# Simple scripts

Use the following to create images:

1..1000 | %{ cp .\1pixel.png "./blobs/img$($_.ToString().PadLeft(4, '0')).png" }