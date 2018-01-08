//
//  Preview.m
//  AiyaVideoRecord
//
//  Created by 汪洋 on 2017/12/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "Preview.h"
#import "OpenglHelper.h"

static const NSString * kVertexShaderString =
@"attribute vec4 position;\n"
"attribute vec2 inputTextureCoordinate;\n"
"varying mediump vec2 v_texCoord;\n"
"uniform mediump mat4 transformMatrix;\n"
"void main()\n"
"{\n"
"    gl_Position = transformMatrix * position;\n"
"    v_texCoord = inputTextureCoordinate;\n"
"}\n";

static const NSString *kFragmentShaderString =
@"precision lowp float;\n"
"uniform sampler2D mTexture;\n"
"varying highp vec2 v_texCoord;\n"
"void main()\n"
"{\n"
"    gl_FragColor = texture2D(mTexture, v_texCoord);\n"
"}\n";

static const GLfloat squareVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat verticalFlipTextureCoordinates[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f,  0.0f,
    1.0f,  0.0f,
};

static const GLfloat noRotationTextureCoordinates[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};

@interface Preview () {
    OpenglHelper *glHelper;
    
    GLuint inputFrameBuffer, inputTexture;
    
    GLuint renderbuffer, displayFrameBuffer;
    GLint backingWidth, backingHeight;
    GLuint program;
    GLint positionAttribute, textureCoordinateAttribute;
    GLint inputTextureUniform;
    GLint transformMatrixUniform;

    GLuint bgraTexture;
}
@end

@implementation Preview

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
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
        [self initGL];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self destroyDisplayFramebuffer];
}

- (void)initGL{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        glHelper = [OpenglHelper share];
        [glHelper useAsCurrentContext];
        
        //初始化GL显示
        program = [glHelper createProgramWithVert:kVertexShaderString frag:kFragmentShaderString];
        positionAttribute = glGetAttribLocation(program, [@"position" UTF8String]);
        textureCoordinateAttribute = glGetAttribLocation(program, [@"inputTextureCoordinate" UTF8String]);
        inputTextureUniform = glGetUniformLocation(program, [@"mTexture" UTF8String]);
        transformMatrixUniform = glGetUniformLocation(program, [@"transformMatrix" UTF8String]);

    });
    
}

- (void)setRenderSuspended:(BOOL)renderSuspended{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        _renderSuspended = renderSuspended;
    });
}

- (void)render:(CVPixelBufferRef)pixelBuffer{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
// ----------旋转图像为正向 绘制开始----------
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!inputFrameBuffer) {
            [self createInputFrameBufferWithWidth:height height:width];
        }
        glBindFramebuffer(GL_FRAMEBUFFER, inputFrameBuffer);
        glViewport(0, 0, height, width);
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glUseProgram(program);
        
        CATransform3D transform3D = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
        GLfloat transformMatrix[16];
        transformMatrix[0] = (GLfloat)transform3D.m11;
        transformMatrix[1] = (GLfloat)transform3D.m21;
        transformMatrix[2] = (GLfloat)transform3D.m31;
        transformMatrix[3] = (GLfloat)transform3D.m41;
        transformMatrix[4] = (GLfloat)transform3D.m12;
        transformMatrix[5] = (GLfloat)transform3D.m22;
        transformMatrix[6] = (GLfloat)transform3D.m32;
        transformMatrix[7] = (GLfloat)transform3D.m42;
        transformMatrix[8] = (GLfloat)transform3D.m13;
        transformMatrix[9] = (GLfloat)transform3D.m23;
        transformMatrix[10] = (GLfloat)transform3D.m33;
        transformMatrix[11] = (GLfloat)transform3D.m43;
        transformMatrix[12] = (GLfloat)transform3D.m14;
        transformMatrix[13] = (GLfloat)transform3D.m24;
        transformMatrix[14] = (GLfloat)transform3D.m34;
        transformMatrix[15] = (GLfloat)transform3D.m44;
        glUniformMatrix4fv(transformMatrixUniform, 1, GL_FALSE, transformMatrix);

        glActiveTexture(GL_TEXTURE1);
        
        if (!bgraTexture) {
            glGenTextures(1, &bgraTexture);
            glBindTexture(GL_TEXTURE_2D, bgraTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        } else {
            glBindTexture(GL_TEXTURE_2D, bgraTexture);
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        glBindTexture(GL_TEXTURE_2D, bgraTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        glUniform1i(inputTextureUniform, 1);
        glActiveTexture(GL_TEXTURE0);
        
        glEnableVertexAttribArray(positionAttribute);
        glEnableVertexAttribArray(textureCoordinateAttribute);
        
        glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
        glVertexAttribPointer(textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, verticalFlipTextureCoordinates);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
// ----------旋转图像为正向 绘制结束----------

// ----------显示纹理数据到视图中 绘制开始----------
        if (!displayFrameBuffer) {
            [self createDisplayFramebuffer];
        }
        glBindFramebuffer(GL_FRAMEBUFFER, displayFrameBuffer);
        glViewport(0, 0, backingWidth, backingHeight);
        
        glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glUseProgram(program);
        
        transform3D = CATransform3DMakeRotation(0, 0, 0, 1);
        transformMatrix[0] = (GLfloat)transform3D.m11;
        transformMatrix[1] = (GLfloat)transform3D.m21;
        transformMatrix[2] = (GLfloat)transform3D.m31;
        transformMatrix[3] = (GLfloat)transform3D.m41;
        transformMatrix[4] = (GLfloat)transform3D.m12;
        transformMatrix[5] = (GLfloat)transform3D.m22;
        transformMatrix[6] = (GLfloat)transform3D.m32;
        transformMatrix[7] = (GLfloat)transform3D.m42;
        transformMatrix[8] = (GLfloat)transform3D.m13;
        transformMatrix[9] = (GLfloat)transform3D.m23;
        transformMatrix[10] = (GLfloat)transform3D.m33;
        transformMatrix[11] = (GLfloat)transform3D.m43;
        transformMatrix[12] = (GLfloat)transform3D.m14;
        transformMatrix[13] = (GLfloat)transform3D.m24;
        transformMatrix[14] = (GLfloat)transform3D.m34;
        transformMatrix[15] = (GLfloat)transform3D.m44;
        glUniformMatrix4fv(transformMatrixUniform, 1, GL_FALSE, transformMatrix);
        
        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(height, width), CGRectMake(0, 0, backingWidth, backingHeight));
        
        CGFloat heightScaling, widthScaling;
        
        //图像填充方式一:拉伸
        //    widthScaling = 1.0;
        //    heightScaling = 1.0;
        
        //图像填充方式二:保持宽高比
        widthScaling = insetRect.size.width / backingWidth;
        heightScaling = insetRect.size.height / backingHeight;
        
        //图像填充方式三:保持宽高比同时填满整个屏幕
        //    widthScaling = backingHeight / insetRect.size.height;
        //    heightScaling = backingWidth / insetRect.size.width;
        
        GLfloat squareVertices[8];
        squareVertices[0] = -widthScaling;
        squareVertices[1] = -heightScaling;
        squareVertices[2] = widthScaling;
        squareVertices[3] = -heightScaling;
        squareVertices[4] = -widthScaling;
        squareVertices[5] = heightScaling;
        squareVertices[6] = widthScaling;
        squareVertices[7] = heightScaling;
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, inputTexture);
        glUniform1i(inputTextureUniform, 1);
        glActiveTexture(GL_TEXTURE0);

        glEnableVertexAttribArray(positionAttribute);
        glEnableVertexAttribArray(textureCoordinateAttribute);
        
        glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);

        glVertexAttribPointer(textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        
        if (!self.renderSuspended) {
            [[glHelper context] presentRenderbuffer:GL_RENDERBUFFER];
        } else {
            NSLog(@"render has stoped");
        }
// ----------显示纹理数据到视图中 绘制结束----------
    });
}

- (void)createInputFrameBufferWithWidth:(int)width height:(int)height{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
        glGenFramebuffers(1, &inputFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, inputFrameBuffer);
        
        glGenTextures(1, &inputTexture);
        glBindTexture(GL_TEXTURE_2D, inputTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, inputTexture, 0);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyInputFramebuffer{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
        if (inputFrameBuffer){
            glDeleteFramebuffers(1, &inputFrameBuffer);
            inputFrameBuffer = 0;
        }
        
        if (inputTexture) {
            glDeleteTextures(1, &inputTexture);
            inputTexture = 0;
        }
        
        
        if (bgraTexture) {
            glDeleteTextures(1, &bgraTexture);
            bgraTexture = 0;
        }
    });
    
}


#pragma mark 渲染到屏幕的Framebuffer
- (void)createDisplayFramebuffer;{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
        glGenFramebuffers(1, &displayFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, displayFrameBuffer);
        
        glGenRenderbuffers(1, &renderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        
        __block CAEAGLLayer *layer;
        dispatch_sync(dispatch_get_main_queue(), ^{
            layer = (CAEAGLLayer *)self.layer;
        });
        
        [[glHelper context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
        
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
        
        if ( (backingWidth == 0) || (backingHeight == 0) )
        {
            [self destroyDisplayFramebuffer];
            return;
        }
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
    });
}

- (void)destroyDisplayFramebuffer;{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
        if (displayFrameBuffer)
        {
            glDeleteFramebuffers(1, &displayFrameBuffer);
            displayFrameBuffer = 0;
        }
        
        if (renderbuffer)
        {
            glDeleteRenderbuffers(1, &renderbuffer);
            renderbuffer = 0;
        }
    });
}

- (void)dealloc{
    [self destroyInputFramebuffer];
    [self destroyDisplayFramebuffer];
}
@end
