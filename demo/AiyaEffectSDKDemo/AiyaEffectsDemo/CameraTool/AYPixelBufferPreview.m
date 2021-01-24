//
//  AYPreview.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2019/12/11.
//  Copyright © 2019 深圳哎吖科技. All rights reserved.
//

#import "AYPixelBufferPreview.h"

static const NSString * kVertexShaderString = @""
"  attribute vec4 position;\n"
"  attribute vec2 inputTextureCoordinate;\n"
"  varying mediump vec2 v_texCoord;\n"
"  \n"
"  void main()\n"
"  {\n"
"    gl_Position = position;\n"
"    v_texCoord = inputTextureCoordinate;\n"
"  }\n";

static const NSString *kFragmentShaderString = @""
"  precision lowp float;\n"
"  uniform sampler2D u_texture;\n"
"  varying highp vec2 v_texCoord;\n"
"  \n"
"  void main()\n"
"  {\n"
"    gl_FragColor = texture2D(u_texture, v_texCoord);\n"
"  }\n";

@interface AYPixelBufferPreview () {
    dispatch_queue_t queue;
    
    CAEAGLLayer *eaglLayer;
    
    EAGLContext *glContext;
    
    GLuint renderBuffer, frameBuffer;
    GLint backingWidth, backingHeight;
    GLuint program;
    GLint positionAttribute, textureCoordinateAttribute;
    GLint inputTextureUniform;

    GLuint texture;
}
@end

@implementation AYPixelBufferPreview

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([self respondsToSelector:@selector(setContentScaleFactor:)]){
            self.contentScaleFactor = [[UIScreen mainScreen] scale];
        }
        
        self.opaque = YES;
        self.hidden = NO;
        eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
        queue = dispatch_queue_create("com.aiya.textureview", nil);
        
        glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        dispatch_sync(queue, ^{
            [EAGLContext setCurrentContext:self->glContext];
            
            [self createProgram];
            
            [self createDisplayRenderBuffer];
        });
        
        _previewRotationMode = kAYPreviewNoRotation;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self destroyDisplayFramebuffer];
}

- (void)setPreviewRotationMode:(AYPreviewRotationMode)previewRotationMode {
    switch (previewRotationMode) {
        case kAYPreviewNoRotation:
            _previewRotationMode = kAYPreviewFlipVertical;
            break;
        case kAYPreviewRotateLeft:
            _previewRotationMode = kAYPreviewRotateRightFlipHorizontal;
            break;
        case kAYPreviewRotateRight:
            _previewRotationMode = kAYPreviewRotateRightFlipVertical;
            break;
        case kAYPreviewRotate180:
            _previewRotationMode = kAYPreviewFlipHorizonal;
            break;
        case kAYPreviewFlipVertical:
            _previewRotationMode = kAYPreviewNoRotation;
            break;
        case kAYPreviewRotateRightFlipHorizontal:
            _previewRotationMode = kAYPreviewRotateLeft;
            break;
        case kAYPreviewRotateRightFlipVertical:
            _previewRotationMode = kAYPreviewRotateRight;
            break;
        case kAYPreviewFlipHorizonal:
            _previewRotationMode = kAYPreviewRotate180;
            break;
    }
}

- (void)render:(CVPixelBufferRef)pixelBuffer {
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int lineSize = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) / 4;
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    void *bgraData = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    [self renderWithBgraData:bgraData width:width height:height lineSize:lineSize];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)renderWithBgraData:(void *)bgraData width:(int)width height:(int)height lineSize:(int)lineSize {

    dispatch_sync(queue, ^{
        [EAGLContext setCurrentContext:self->glContext];
        
        int outputWidth = width;
        int outputHeight = height;
        
        if ([AYPixelBufferPreview needExchangeWidthAndHeightWithPreviewRotation:self.previewRotationMode]) {
            int temp = outputWidth;
            outputWidth = outputHeight;
            outputHeight = temp;
        }
        
        // 创建Program
        if (!self->program) {
            [self createProgram];
        }
        
        // 创建显示时的RenderBuffer
        if (!self->renderBuffer) {
            [self createDisplayRenderBuffer];
        }
        
        // 创建纹理
        if (!self->texture) {
            glGenTextures(1, &self->texture);
            glBindTexture(GL_TEXTURE_2D, self->texture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, self->frameBuffer);

        glViewport(0, 0, self->backingWidth, self->backingHeight);

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glUseProgram(self->program);

        glActiveTexture(GL_TEXTURE1);

        glBindTexture(GL_TEXTURE_2D, self->texture);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, lineSize, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, bgraData);

        glUniform1i(self->inputTextureUniform, 1);

        CGFloat heightScaling, widthScaling;

        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(outputWidth, outputHeight), CGRectMake(0, 0, self->backingWidth, self->backingHeight));
        switch (self.previewContentMode) {
            case AYPreivewContentModeScaleToFill: // 填充
                widthScaling = 1.0;
                heightScaling = 1.0;
                break;

            case AYPreivewContentModeScaleAspectFit: //保持宽高比
                widthScaling = insetRect.size.width / self->backingWidth;
                heightScaling = insetRect.size.height / self->backingHeight;
                break;

            case AYPreivewContentModeScaleAspectFill: //保持宽高比同时填满整个屏幕
                widthScaling = self->backingHeight / insetRect.size.height;
                heightScaling = self->backingWidth / insetRect.size.width;
                break;
        }

        GLfloat squareVertices[8];
        squareVertices[0] = -widthScaling;
        squareVertices[1] = -heightScaling;
        squareVertices[2] = widthScaling;
        squareVertices[3] = -heightScaling;
        squareVertices[4] = -widthScaling;
        squareVertices[5] = heightScaling;
        squareVertices[6] = widthScaling;
        squareVertices[7] = heightScaling;

        glVertexAttribPointer(self->positionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);

        const GLfloat *textureCoordinates = [AYPixelBufferPreview textureCoordinatesForRotation:self.previewRotationMode];
        
        // 处理lineSize != width
        GLfloat coordinates[8];
        for (int x = 0; x < 8; x++) {
            if (x % 2 == 0 && textureCoordinates[x] == 1) {
                coordinates[x] = (float)width / (float)lineSize;
            } else {
                coordinates[x] = textureCoordinates[x];
            }
        }

        glVertexAttribPointer(self->textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, coordinates);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glBindRenderbuffer(GL_RENDERBUFFER, self->renderBuffer);
        
        [self->glContext presentRenderbuffer:GL_RENDERBUFFER];
    });
}

- (void)createProgram {
    program = [AYPixelBufferPreview createProgramWithVert:kVertexShaderString frag:kFragmentShaderString];
    positionAttribute = glGetAttribLocation(program, [@"position" UTF8String]);
    textureCoordinateAttribute = glGetAttribLocation(program, [@"inputTextureCoordinate" UTF8String]);
    inputTextureUniform = glGetUniformLocation(program, [@"u_texture" UTF8String]);
    
    glEnableVertexAttribArray(self->positionAttribute);
    glEnableVertexAttribArray(self->textureCoordinateAttribute);
}

- (void)destroyProgram {
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
}

- (void)createDisplayRenderBuffer {
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);

    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);

    [self->glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);

    if ((backingWidth == 0) || (backingHeight == 0)) {
        [self destroyDisplayFramebuffer];
        return;
    }

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
}

- (void)destroyDisplayFramebuffer {
    if (frameBuffer) {
        glDeleteFramebuffers(1, &frameBuffer);
        frameBuffer = 0;
    }

    if (renderBuffer) {
        glDeleteRenderbuffers(1, &renderBuffer);
        renderBuffer = 0;
    }
}

- (void)releaseGLResources {
    dispatch_sync(queue, ^{
        [EAGLContext setCurrentContext:self->glContext];
        
        [self destroyProgram];
        [self destroyDisplayFramebuffer];
    });
    
}

- (void)dealloc{
    [self releaseGLResources];
}

@end



@implementation AYPixelBufferPreview (OpenGLHelper)

// 编译 shader
+ (GLuint)createProgramWithVert:(const NSString *)vShaderString frag:(const NSString *)fShaderString {
    
    GLuint program = glCreateProgram();
    GLuint vertShader = 0, fragShader = 0;
    if (![self compileShader:&vertShader
                        type:GL_VERTEX_SHADER
                      string:vShaderString]){
        NSLog(@"Failed to compile vertex shader");
    }
    
    if (![self compileShader:&fragShader
                        type:GL_FRAGMENT_SHADER
                      string:fShaderString]){
        NSLog(@"Failed to compile fragment shader");
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    
    GLint status;
    
    glLinkProgram(program);
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        NSLog(@"Failed to link shader");
    
    if (vertShader)
    {
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader)
    {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    
    return program;
}

+ (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const NSString *)shaderString {
    
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[shaderString UTF8String];
    if (!source){
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0){
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            NSLog(@"Failed to compile shader %s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

+ (const GLfloat *)textureCoordinatesForRotation:(AYPreviewRotationMode)rotationMode {
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    switch(rotationMode)
    {
        case kAYPreviewNoRotation: return noRotationTextureCoordinates;
        case kAYPreviewRotateLeft: return rotateLeftTextureCoordinates;
        case kAYPreviewRotateRight: return rotateRightTextureCoordinates;
        case kAYPreviewFlipVertical: return verticalFlipTextureCoordinates;
        case kAYPreviewFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kAYPreviewRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kAYPreviewRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kAYPreviewRotate180: return rotate180TextureCoordinates;
    }
}

+ (BOOL)needExchangeWidthAndHeightWithPreviewRotation:(AYPreviewRotationMode)rotationMode {
    switch(rotationMode)
    {
        case kAYPreviewNoRotation: return NO;
        case kAYPreviewRotateLeft: return YES;
        case kAYPreviewRotateRight: return YES;
        case kAYPreviewFlipVertical: return NO;
        case kAYPreviewFlipHorizonal: return NO;
        case kAYPreviewRotateRightFlipVertical: return YES;
        case kAYPreviewRotateRightFlipHorizontal: return YES;
        case kAYPreviewRotate180: return NO;
    }
}

@end
