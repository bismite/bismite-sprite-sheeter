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
## 4.0.2 2023/04/10
- license change to MIT License
- update mruby 3.2.0, SDL-2.26.5, SDL_image 2.6.3
## 3.0.0 2022/11/15
- remove msgpack output
## 2.0.3 2022/11/12
- SDL update(macos/mingw)

# License
Copyright (c) 2021 kbys <work4kbys@gmail.com>

MIT License
