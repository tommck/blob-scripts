# Simple scripts

Use the following to create images:

0..999 | %{ cp .\1pixel.png "./blobs/img$($_.ToString().PadLeft(4, '0')).png" }