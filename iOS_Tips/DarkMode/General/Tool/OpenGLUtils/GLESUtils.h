//
//  GLESUtils.h
//
//  Created by kesalin@gmail.com on 12-11-25.
//  Copyright (c) 2012 年 http://blog.csdn.net/kesalin/. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>

@interface GLESUtils : NSObject

// Create a shader object, load the shader source string, and compile the shader.
//
+(GLuint)loadShader:(GLenum)type withString:(NSString *)shaderString;

+(GLuint)loadShader:(GLenum)type withFilepath:(NSString *)shaderFilepath;

//
///
/// Load a vertex and fragment shader, create a program object, link program.
/// Errors output to log.
/// vertexShaderFilepath Vertex shader source file path.
/// fragmentShaderFilepath Fragment shader source file path
/// return A new program object linked with the vertex/fragment shader pair, 0 on failure
//
+(GLuint)loadProgram:(NSString *)vertexShaderFilepath withFragmentShaderFilepath:(NSString *)fragmentShaderFilepath;

@end
