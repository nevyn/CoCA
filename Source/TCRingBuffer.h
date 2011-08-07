//
//  TCRingBuffer.h
//  TCRingBuffer
//
//  Created by Joachim Bengtsson on 2011-08-07.
//  Copyright 2011 Third Cog Software. All rights reserved.
//



@interface TCRingBuffer : NSObject
-(id)initWithCapacity:(NSUInteger)capacity;
-(void)getBytes:(char*)bytes ofLength:(NSUInteger)length;
-(void)writeBytes:(const char*)bytes ofLength:(NSUInteger)length;
@property NSUInteger capacity;
-(void)reset;
@end
