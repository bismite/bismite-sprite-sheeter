# bismite-sprite-sheeter

<https://github.com/bismite/bismite-sprite-sheeter>

## Usage

```
bismite-sprite-sheeter path/to/src/dir path/to/dst/dir
```

This command refers to `config.json` and `crop.json` in the source directory.

### config.json

```
{
  "width": 4096,
  "height": 4096,
  "margin": 2,
  "heuristics": "BottomLeft",
  "exclude_crop": ["foo/bar"],
  "sort": "random"
}
```

- heuristics
  - `BottomLeft`
  - `BestAreaFit`
  - `BestLongSideFit`
  - `BestShortSideFit`
- sort
  - `longer`
  - `height`
  - `width`
  - `area`
  - `random`
  - `name`

### crop.json

```
[
  ["foo/bar/cropped.png", [XinOriginalImage, YinOriginalImage, OriginalImageW, OriginalImageH]]
]
```

# Changelog
## 2.0.2 2022/11/12
- SDL update(macos/mingw)

# License
Copyright 2021-2022 kbys <work4kbys@gmail.com>

Apache License Version 2.0
