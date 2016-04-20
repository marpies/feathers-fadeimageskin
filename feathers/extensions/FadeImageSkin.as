/*
 Original work Copyright 2012-2016 Bowler Hat LLC. All rights reserved.
 Modified work Copyright 2016 Marcel Piestansky

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the copyright holders.
 */
package feathers.extensions {

    import feathers.controls.ButtonState;
    import feathers.controls.ToggleButton;
    import feathers.core.IFeathersControl;
    import feathers.core.IMeasureDisplayObject;
    import feathers.core.IStateContext;
    import feathers.core.IStateObserver;
    import feathers.core.IToggle;
    import feathers.events.FeathersEventType;

    import flash.geom.Rectangle;

    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.core.Starling;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.events.Event;
    import starling.textures.Texture;

    /**
     * A skin for Feathers components that displays a texture. Has the ability
     * to change its texture based on the current state of the Feathers
     * component that is being skinned. Uses two Image objects to achieve
     * a fading effect when the state skin changes.
     *
     * <listing version="3.0">
     * function setButtonSkin( button:Button ):void
     * {
	 *     var skin:FadeImageSkin = new FadeImageSkin( upTexture );
	 *     skin.setTextureForState( ButtonState.DOWN, downTexture );
	 *     skin.setTextureForState( ButtonState.HOVER, hoverTexture );
	 *     button.defaultSkin = skin;
	 * }
     *
     * var button:Button = new Button();
     * button.label = "Click Me";
     * button.styleProvider = new AddOnFunctionStyleProvider( setButtonSkin, button.styleProvider );
     * this.addChild( button );</listing>
     */
    public class FadeImageSkin extends DisplayObjectContainer implements IMeasureDisplayObject, IStateObserver {

        protected static const JUGGLER:Juggler = Starling.juggler;

        protected var mExplicitWidth:Number;
        protected var mExplicitHeight:Number;
        protected var mExplicitMinWidth:Number;
        protected var mExplicitMinHeight:Number;
        protected var mPreviousState:String;
        protected var mPreviousSkinTweenID:uint;
        protected var mActiveSkinTweenID:uint;
        protected var mColorTweenID:uint;
        protected var mToggleTransitionDC:uint;
        protected var mFadeInDuration:Number;
        protected var mFadeInTransition:String;
        protected var mFadeOutDuration:Number;
        protected var mFadeOutTransition:String;
        protected var mTweenColorChange:Boolean;
        protected var mColorTweenDuration:Number;
        protected var mColorTweenTransition:String;

        protected var mStateContext:IStateContext;
        protected var mStateToTexture:Object;
        protected var mStateToColor:Object = {};
        protected var mScale9Grid:Rectangle;

        protected var mDefaultTexture:Texture;
        protected var mDisabledTexture:Texture;
        protected var mSelectedTexture:Texture;

        protected var mDefaultColor:uint;
        protected var mDisabledColor:uint;
        protected var mSelectedColor:uint;

        protected var mPrevSkin:Image;
        protected var mActiveSkin:Image;

        public function FadeImageSkin( texture:Texture ) {
            super();

            mDefaultTexture = texture;
            mFadeInDuration = mFadeOutDuration = mColorTweenDuration = 0.5;
            mFadeInTransition = mColorTweenTransition = Transitions.EASE_OUT;
            mFadeOutTransition = Transitions.EASE_IN;
            mDefaultColor = uint.MAX_VALUE;
            mDisabledColor = uint.MAX_VALUE;
            mSelectedColor = uint.MAX_VALUE;

            mStateToTexture = {};
        }

        /**
         *
         *
         * Public API
         *
         *
         */

        /**
         * Gets the texture to be used by the skin when the context's
         * <code>currentState</code> property matches the specified state value.
         *
         * <p>If a texture is not defined for a specific state, returns
         * <code>null</code>.</p>
         *
         * @see #setTextureForState()
         */
        public function getTextureForState( state:String ):Texture {
            return mStateToTexture[state] as Texture;
        }

        /**
         * Sets the texture to be used by the skin when the context's
         * <code>currentState</code> property matches the specified state value.
         *
         * <p>If a texture is not defined for a specific state, the value of the
         * <code>defaultTexture</code> property will be used instead.</p>
         *
         * @see #defaultTexture
         */
        public function setTextureForState( state:String, texture:Texture ):void {
            if( texture !== null ) {
                mStateToTexture[state] = texture;
            } else {
                delete mStateToTexture[state];
            }
            updateTextureFromContext();
        }

        /**
         * Gets the color to be used by the skin when the context's
         * <code>currentState</code> property matches the specified state value.
         *
         * <p>If a color is not defined for a specific state, returns
         * <code>uint.MAX_VALUE</code>.</p>
         *
         * @see #setColorForState()
         */
        public function getColorForState( state:String ):uint {
            if( state in mStateToColor ) {
                return mStateToColor[state] as uint;
            }
            return uint.MAX_VALUE;
        }

        /**
         * Sets the color to be used by the skin when the context's
         * <code>currentState</code> property matches the specified state value.
         *
         * <p>If a color is not defined for a specific state, the value of the
         * <code>defaultTexture</code> property will be used instead.</p>
         *
         * <p>To clear a state's color, pass in <code>uint.MAX_VALUE</code>.</p>
         *
         * @see #defaultColor
         * @see #getColorForState()
         */
        public function setColorForState( state:String, color:uint ):void {
            if( color !== uint.MAX_VALUE ) {
                mStateToColor[state] = color;
            } else {
                delete mStateToColor[state];
            }
            updateColorFromContext();
        }

        /**
         *
         *
         * Private API
         *
         *
         */

        private function getImage( texture:Texture, image:Image ):Image {
            if( image ) {
                image.texture = texture;
            } else {
                image = new Image( texture );
            }
            if( mScale9Grid !== null && (image.scale9Grid === null || !image.scale9Grid.equals( mScale9Grid )) ) {
                image.scale9Grid = mScale9Grid;
            }
            return image;
        }

        private function resizeImage( image:Image ):void {
            if( mExplicitWidth === mExplicitWidth && //!isNaN
                    image.width !== mExplicitWidth ) {
                image.width = mExplicitWidth;
            }
            if( mExplicitHeight === mExplicitHeight && //!isNaN
                    image.height !== mExplicitHeight ) {
                image.height = mExplicitHeight;
            }
        }

        private function delayedTransition():void {
            mToggleTransitionDC = 0;
            updateTextureFromContext();
            updateColorFromContext();
        }

        /**
         *
         *
         * Protected API
         *
         *
         */

        protected function updateTextureFromContext():void {
            if( mStateContext === null ) {
                if( mDefaultTexture !== null && mActiveSkin === null ) {
                    mActiveSkin = new Image( mDefaultTexture );
                    addChildAt( mActiveSkin, 0 );
                }
                return;
            }
            var currentState:String = mStateContext.currentState;
            if( mPreviousState !== currentState ) {
                var texture:Texture = mStateToTexture[currentState] as Texture;
                if( texture === null &&
                        mDisabledTexture !== null &&
                        mStateContext is IFeathersControl && !IFeathersControl( mStateContext ).isEnabled ) {
                    texture = mDisabledTexture;
                }
                var isToggle:Boolean = mStateContext is IToggle;
                if( texture === null &&
                        mSelectedTexture !== null &&
                        isToggle &&
                        IToggle( mStateContext ).isSelected ) {
                    texture = mSelectedTexture;
                }
                if( texture === null ) {
                    texture = mDefaultTexture;
                }

                /* By default, state change from DOWN to UP_AND_SELECTED has this flow:
                 *  DOWN -> UP -> UP_AND_SELECTED
                 * This delayed call prevents immediate change to UP state when it is not needed.
                 * Is there a better way to prevent it? Please, show me. */
                if( mToggleTransitionDC > 0 ) {
                    JUGGLER.removeByID( mToggleTransitionDC );
                    mToggleTransitionDC = 0;
                }
                if( isToggle &&
                        ((mPreviousState == ButtonState.DOWN && currentState == ButtonState.UP) ||
                        (mPreviousState == ButtonState.DOWN_AND_SELECTED && currentState == ButtonState.UP_AND_SELECTED)) ) {
                    mPreviousState = null;
                    mToggleTransitionDC = JUGGLER.delayCall( delayedTransition, 0.05 );
                    return;
                }

                mPreviousState = currentState;
                var prevSkin:Image = null;
                var activeSkin:Image = null;
                if( mActiveSkin !== null ) {
                    /* Active image already has the texture we want to transition to */
                    if( mActiveSkin.texture == texture ) return;
                    /* The current skin becomes previous so that it can be faded out */
                    if( mActiveSkin.texture !== null ) {
                        mPrevSkin = getImage( mActiveSkin.texture, mPrevSkin );
                        mPrevSkin.color = mActiveSkin.color;
                        resizeImage( mPrevSkin );
                        addChildAt( mPrevSkin, 0 );
                        prevSkin = mPrevSkin;
                    }
                } else if( mPrevSkin !== null ) {
                    mPrevSkin.removeFromParent();
                }
                /* If there is a new skin then assign it to Image */
                if( texture !== null ) {
                    mActiveSkin = getImage( texture, mActiveSkin );
                    mActiveSkin.color = 0xFFFFFF;
                    resizeImage( mActiveSkin );
                    addChild( mActiveSkin );
                    activeSkin = mActiveSkin;
                } else if( mActiveSkin !== null ) {
                    mActiveSkin.removeFromParent();
                    mActiveSkin.texture = null;
                }
                animate( activeSkin, prevSkin );
            }
        }

        protected function updateColorFromContext():void {
            if( mStateContext === null ) {
                if( mDefaultColor !== uint.MAX_VALUE && mActiveSkin !== null && mActiveSkin.texture !== null ) {
                    mActiveSkin.color = mDefaultColor;
                }
                return;
            }
            var color:uint = uint.MAX_VALUE;
            var currentState:String = mStateContext.currentState;
            if( currentState in mStateToColor ) {
                color = mStateToColor[currentState] as uint;
            }
            if( color === uint.MAX_VALUE &&
                    mDisabledColor !== uint.MAX_VALUE &&
                    mStateContext is IFeathersControl && !IFeathersControl( mStateContext ).isEnabled ) {
                color = mDisabledColor;
            }
            if( color === uint.MAX_VALUE &&
                    mSelectedColor !== uint.MAX_VALUE &&
                    mStateContext is IToggle &&
                    IToggle( mStateContext ).isSelected ) {
                color = mSelectedColor;
            }
            if( color === uint.MAX_VALUE ) {
                color = mDefaultColor;
            }
            if( color !== uint.MAX_VALUE && mActiveSkin !== null && mActiveSkin.texture !== null ) {
                if( mTweenColorChange ) {
                    if( mColorTweenID > 0 ) {
                        JUGGLER.removeByID( mColorTweenID );
                    }
                    mColorTweenID = JUGGLER.tween( mActiveSkin, mColorTweenDuration, {
                        color: color,
                        transition: mColorTweenTransition,
                        onComplete: function():void {
                            mColorTweenID = 0;
                        }
                    } );
                } else {
                    mActiveSkin.color = color;
                }
            }
        }

        protected function animate( activeSkin:Image, prevSkin:Image ):void {
            if( prevSkin !== null ) {
                prevSkin.alpha = 1;
                if( mPreviousSkinTweenID > 0 ) {
                    JUGGLER.removeByID( mPreviousSkinTweenID );
                }
                mPreviousSkinTweenID = JUGGLER.tween( prevSkin, mFadeOutDuration, {
                    alpha: 0,
                    transition: mFadeOutTransition,
                    onComplete: function ():void {
                        mPreviousSkinTweenID = 0;
                    }
                } );
            }
            if( activeSkin !== null ) {
                activeSkin.alpha = 0;
                if( mActiveSkinTweenID > 0 ) {
                    JUGGLER.removeByID( mActiveSkinTweenID );
                }
                mActiveSkinTweenID = JUGGLER.tween( activeSkin, mFadeInDuration, {
                    alpha: 1,
                    transition: mFadeInTransition,
                    onComplete: function ():void {
                        mActiveSkinTweenID = 0;
                    }
                } );
            }
        }

        protected function onStateContextChanged():void {
            updateTextureFromContext();
            updateColorFromContext();
        }

        /**
         *
         *
         * Getters / Setters
         *
         *
         */

        /**
         * When the skin observes a state context, the skin may change its
         * <code>Texture</code> based on the current state of that context.
         * Typically, a relevant component will automatically assign itself as
         * the state context of its skin, so this property is considered to be
         * for internal use only.
         *
         * @default null
         *
         * @see #setTextureForState()
         */
        public function get stateContext():IStateContext {
            return mStateContext;
        }

        public function set stateContext( value:IStateContext ):void {
            if( mStateContext === value ) {
                return;
            }
            if( mStateContext ) {
                mStateContext.removeEventListener( FeathersEventType.STATE_CHANGE, onStateContextChanged );
            }
            mStateContext = value;
            if( mStateContext ) {
                mStateContext.addEventListener( FeathersEventType.STATE_CHANGE, onStateContextChanged );
            }
            updateTextureFromContext();
            updateColorFromContext();
        }

        /**
         * The value passed to the <code>width</code> property setter. If the
         * <code>width</code> property has not be set, returns <code>NaN</code>.
         *
         * @see #width
         */
        public function get explicitWidth():Number {
            return mExplicitWidth;
        }

        override public function set width( value:Number ):void {
            if( mExplicitWidth === value ) {
                return;
            }
            if( value !== value && mExplicitWidth !== mExplicitWidth ) {
                return;
            }
            mExplicitWidth = value;
            if( mActiveSkin !== null ) {
                if( value === value ) { //!isNaN
                    mActiveSkin.width = value;
                } else { // return to the original width of the texture
                    mActiveSkin.readjustSize();
                }
            }
            dispatchEventWith( Event.RESIZE );
        }

        override public function get width():Number {
            return mActiveSkin ? mActiveSkin.width : NaN;
        }

        /**
         * The value passed to the <code>height</code> property setter. If the
         * <code>height</code> property has not be set, returns
         * <code>NaN</code>.
         *
         * @see #height
         */
        public function get explicitHeight():Number {
            return mExplicitHeight;
        }

        override public function set height( value:Number ):void {
            if( mExplicitHeight === value ) {
                return;
            }
            if( value !== value && mExplicitHeight !== mExplicitHeight ) {
                return;
            }
            mExplicitHeight = value;
            if( mActiveSkin !== null ) {
                if( value === value ) { //!isNaN
                    mActiveSkin.height = value;
                } else { //return to the original height of the texture
                    mActiveSkin.readjustSize();
                }
            }
            dispatchEventWith( Event.RESIZE );
        }

        override public function get height():Number {
            return mActiveSkin ? mActiveSkin.height : NaN;
        }

        /**
         * The value passed to the <code>minWidth</code> property setter. If the
         * <code>minWidth</code> property has not be set, returns
         * <code>NaN</code>.
         *
         * @see #minWidth
         */
        public function get explicitMinWidth():Number {
            return mExplicitMinWidth;
        }

        public function get minWidth():Number {
            if( mExplicitMinWidth === mExplicitMinWidth ) { //!isNaN
                return mExplicitMinWidth;
            }
            return 0;
        }

        public function set minWidth( value:Number ):void {
            if( mExplicitMinWidth === value ) {
                return;
            }
            if( value !== value && mExplicitMinWidth !== mExplicitMinWidth ) {
                return;
            }
            mExplicitMinWidth = value;
            dispatchEventWith( Event.RESIZE );
        }

        /**
         * The value passed to the <code>minHeight</code> property setter. If
         * the <code>minHeight</code> property has not be set, returns
         * <code>NaN</code>.
         *
         * @see #minHeight
         */
        public function get explicitMinHeight():Number {
            return mExplicitMinHeight;
        }

        public function get minHeight():Number {
            if( mExplicitMinHeight === mExplicitMinHeight ) { //!isNaN
                return mExplicitMinHeight;
            }
            return 0;
        }

        public function set minHeight( value:Number ):void {
            if( mExplicitMinHeight === value ) {
                return;
            }
            if( value !== value && mExplicitMinHeight !== mExplicitMinHeight ) {
                return;
            }
            mExplicitMinHeight = value;
            dispatchEventWith( Event.RESIZE );
        }

        /**
         * The default texture that the skin will display. If the component
         * being skinned supports states, the texture for a specific state may
         * be specified using the <code>setTextureForState()</code> method. If
         * no texture has been specified for the current state, the default
         * texture will be used.
         *
         * <p>In the following example, the default texture is specified in the
         * constructor:</p>
         *
         * <listing version="3.0">
         * var skin:FadeImageSkin = new FadeImageSkin( texture );</listing>
         *
         * <p>In the following example, the default texture is specified by
         * setting the property:</p>
         *
         * <listing version="3.0">
         * var skin:FadeImageSkin = new FadeImageSkin();
         * skin.defaultTexture = texture;</listing>
         *
         * @default null
         *
         * @see #disabledTexture
         * @see #selectedTexture
         * @see #setTextureForState()
         * @see http://doc.starling-framework.org/current/starling/textures/Texture.html starling.textures.Texture
         */
        public function get defaultTexture():Texture {
            return mDefaultTexture;
        }

        /**
         * @private
         */
        public function set defaultTexture( value:Texture ):void {
            if( mDefaultTexture === value ) {
                return;
            }
            mDefaultTexture = value;
            updateTextureFromContext();
        }

        /**
         * The texture to display when the <code>stateContext</code> is
         * an <code>IFeathersControl</code> and its <code>isEnabled</code>
         * property is <code>false</code>. If a texture has been specified for
         * the context's current state with <code>setTextureForState()</code>,
         * it will take precedence over the <code>disabledTexture</code>.
         *
         * <p>In the following example, the disabled texture is changed:</p>
         *
         * <listing version="3.0">
         * var skin:FadeImageSkin = new FadeImageSkin( upTexture );
         * skin.disabledTexture = disabledTexture;
         * button.skin = skin;
         * button.isEnabled = false;</listing>
         *
         * @default null
         *
         * @see #defaultTexture
         * @see #selectedTexture
         * @see #setTextureForState()
         * @see http://doc.starling-framework.org/current/starling/textures/Texture.html starling.textures.Texture
         */
        public function get disabledTexture():Texture {
            return mDisabledTexture;
        }

        /**
         * @private
         */
        public function set disabledTexture( value:Texture ):void {
            mDisabledTexture = value;
        }

        /**
         * The texture to display when the <code>stateContext</code> is
         * an <code>IToggle</code> instance and its <code>isSelected</code>
         * property is <code>true</code>. If a texture has been specified for
         * the context's current state with <code>setTextureForState()</code>,
         * it will take precedence over the <code>selectedTexture</code>.
         *
         * <p>In the following example, the selected texture is changed:</p>
         *
         * <listing version="3.0">
         * var skin:FadeImageSkin = new FadeImageSkin( upTexture );
         * skin.selectedTexture = selectedTexture;
         * toggleButton.skin = skin;
         * toggleButton.isSelected = true;</listing>
         *
         * @default null
         *
         * @see #defaultTexture
         * @see #disabledTexture
         * @see #setTextureForState()
         * @see http://doc.starling-framework.org/current/starling/textures/Texture.html starling.textures.Texture
         */
        public function get selectedTexture():Texture {
            return mSelectedTexture;
        }

        /**
         * @private
         */
        public function set selectedTexture( value:Texture ):void {
            mSelectedTexture = value;
        }

        /**
         * Scaling grid used for the internal images.
         *
         * @see http://doc.starling-framework.org/current/starling/display/Image.html#scale9Grid starling.display.Image
         */
        public function get scale9Grid():Rectangle {
            return mScale9Grid;
        }

        /**
         * @private
         */
        public function set scale9Grid( value:Rectangle ):void {
            mScale9Grid = value;

            if( mActiveSkin !== null ) {
                mActiveSkin.scale9Grid = value;
            }
        }

        /**
         * The duration of the fade in Tween, in seconds.
         *
         * @default 0.5
         */
        public function get fadeInDuration():Number {
            return mFadeInDuration;
        }

        /**
         * @private
         */
        public function set fadeInDuration( value:Number ):void {
            mFadeInDuration = value;
        }

        /**
         * The duration of the fade out Tween, in seconds.
         *
         * @default 0.5
         */
        public function get fadeOutDuration():Number {
            return mFadeOutDuration;
        }

        /**
         * @private
         */
        public function set fadeOutDuration( value:Number ):void {
            mFadeOutDuration = value;
        }

        /**
         * Name of the transition used to fade in current skin.
         *
         * @default starling.animation.Transitions.EASE_OUT
         *
         * @see http://doc.starling-framework.org/current/starling/animation/Transitions.html starling.animation.Transitions
         */
        public function get fadeInTransition():String {
            return mFadeInTransition;
        }

        /**
         * @private
         */
        public function set fadeInTransition( value:String ):void {
            mFadeInTransition = value;
        }

        /**
         * Name of the transition used to fade out previous skin.
         *
         * @default starling.animation.Transitions.EASE_IN
         *
         * @see http://doc.starling-framework.org/current/starling/animation/Transitions.html starling.animation.Transitions
         */
        public function get fadeOutTransition():String {
            return mFadeOutTransition;
        }

        /**
         * @private
         */
        public function set fadeOutTransition( value:String ):void {
            mFadeOutTransition = value;
        }

        /**
         * Determines if a color change is animated when component's state changes.
         * Useful when having a single skin texture for all states but various colors.
         *
         * @default false
         */
        public function get tweenColorChange():Boolean {
            return mTweenColorChange;
        }

        /**
         * @private
         */
        public function set tweenColorChange( value:Boolean ):void {
            mTweenColorChange = value;
        }

        /**
         * Duration of the tween that changes the skin color.
         *
         * @default 0.5
         */
        public function get colorTweenDuration():Number {
            return mColorTweenDuration;
        }

        /**
         * @private
         */
        public function set colorTweenDuration( value:Number ):void {
            mColorTweenDuration = value;
        }

        /**
         * Transition of the tween that changes the skin color.
         *
         * @default starling.animation.Transitions.EASE_OUT
         *
         * @see http://doc.starling-framework.org/current/starling/animation/Transitions.html starling.animation.Transitions
         */
        public function get colorTweenTransition():String {
            return mColorTweenTransition;
        }

        /**
         * @private
         */
        public function set colorTweenTransition( value:String ):void {
            mColorTweenTransition = value;
        }

        /**
         * The default color to use to tint the skin. If the component
         * being skinned supports states, the color for a specific state may
         * be specified using the <code>setColorForState()</code> method. If
         * no color has been specified for the current state, the default
         * color will be used.
         *
         * <p>A value of <code>uint.MAX_VALUE</code> means that the
         * <code>color</code> property will not be changed when the context's
         * state changes.</p>
         *
         * <p>In the following example, the default color is specified:</p>
         *
         * <listing version="3.0">
         * var skin:FadeImageSkin = new FadeImageSkin();
         * skin.defaultColor = 0x9f0000;</listing>
         *
         * @default uint.MAX_VALUE
         *
         * @see #disabledColor
         * @see #selectedColor
         * @see #setColorForState()
         */
        public function get defaultColor():uint {
            return mDefaultColor;
        }

        /**
         * @private
         */
        public function set defaultColor( value:uint ):void {
            if( mDefaultColor === value ) {
                return;
            }
            mDefaultColor = value;
            updateColorFromContext();
        }

        /**
         * The color to tint the skin when the <code>stateContext</code> is
         * an <code>IFeathersControl</code> and its <code>isEnabled</code>
         * property is <code>false</code>. If a color has been specified for
         * the context's current state with <code>setColorForState()</code>,
         * it will take precedence over the <code>disabledColor</code>.
         *
         * <p>A value of <code>uint.MAX_VALUE</code> means that the
         * <code>disabledColor</code> property cannot affect the tint when the
         * context's state changes.</p>
         *
         * <p>In the following example, the disabled color is changed:</p>
         *
         * <listing version="3.0">
         * var skin:FadeImageSkin = new FadeImageSkin();
         * skin.defaultColor = 0xffffff;
         * skin.disabledColor = 0x999999;
         * button.skin = skin;
         * button.isEnabled = false;</listing>
         *
         * @default uint.MAX_VALUE
         *
         * @see #defaultColor
         * @see #selectedColor
         * @see #setColorForState()
         */
        public function get disabledColor():uint {
            return mDisabledColor;
        }

        /**
         * @private
         */
        public function set disabledColor( value:uint ):void {
            if( mDisabledColor === value ) {
                return;
            }
            mDisabledColor = value;
            updateColorFromContext();
        }

        /**
         * The color to tint the skin when the <code>stateContext</code> is
         * an <code>IToggle</code> instance and its <code>isSelected</code>
         * property is <code>true</code>. If a color has been specified for
         * the context's current state with <code>setColorForState()</code>,
         * it will take precedence over the <code>selectedColor</code>.
         *
         * <p>In the following example, the selected color is changed:</p>
         *
         * <listing version="3.0">
         * var skin:FadeImageSkin = new FadeImageSkin();
         * skin.defaultColor = 0xffffff;
         * skin.selectedColor = 0xffcc00;
         * toggleButton.skin = skin;
         * toggleButton.isSelected = true;</listing>
         *
         * @default uint.MAX_VALUE
         *
         * @see #defaultColor
         * @see #disabledColor
         * @see #setColorForState()
         */
        public function get selectedColor():uint {
            return mSelectedColor;
        }

        /**
         * @private
         */
        public function set selectedColor( value:uint ):void {
            if( mSelectedColor === value ) {
                return;
            }
            mSelectedColor = value;
            updateColorFromContext();
        }

    }

}
