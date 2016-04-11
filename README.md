# FadeImageSkin for Feathers

Extension for Feathers library that enables alpha transition between different component state skins.

## Overview

Usage is identical to the original [ImageSkin](https://github.com/BowlerHatLLC/feathers/blob/master/source/feathers/skins/ImageSkin.as):

```as3
import feathers.extensions.FadeImageSkin;
...
var skin:FadeImageSkin = new FadeImageSkin( upTexture );
skin.setTextureForState( ButtonState.DOWN, downTexture );
skin.setTextureForState( ButtonState.DISABLED, disabledTexture );
skin.scale9Grid = scale9Grid;
button.defaultSkin = skin;
```

You can specify duration and transition for fade in and fade out Tweens.

```as3
// These are all default values
skin.fadeInDuration = 0.5;
skin.fadeInTransition = Transitions.EASE_OUT;
skin.fadeOutDuration = 0.5;
skin.fadeOutTransition = Transitions.EASE_IN;
```

As with the original ImageSkin, you can set a color for each state:

```as3
skin.setColorForState( ButtonState.UP, 0x0000FF );
skin.setColorForState( ButtonState.DOWN, 0xFF0000 );
```

Furthermore, you can enable tweening of the color between each state which is useful if you are using a single texture.

```as3
var skin:FadeImageSkin = new FadeImageSkin( defaultTexture );
skin.setColorForState( ButtonState.UP, 0x0000FF );
skin.setColorForState( ButtonState.DOWN, 0xFF0000 );
skin.tweenColorChange = true;
skin.colorTweenDuration = 0.5;
skin.colorTweenTransition = Transitions.EASE_OUT;
button.defaultSkin = skin;
```

## Requirements

* [Starling Framework 2.0+](https://github.com/Gamua/Starling-Framework)
* [Feathers 3.0+](https://github.com/BowlerHatLLC/feathers)

## Author
[Marcel Piestansky](https://twitter.com/marpies)
