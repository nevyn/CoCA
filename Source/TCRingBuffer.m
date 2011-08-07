//
//  TCRingBuffer.m
//  TCRingBuffer
//
//  Created by Joachim Bengtsson on 2011-08-07.
//  Copyright 2011 Third Cog Software. All rights reserved.
//

#import "TCRingBuffer.h"

@interface TCRingBuffer ()
@property(retain) NSMutableData *storage;
@property NSInteger start, end;
@property(retain) NSCondition *writeCondition, *readCondition;
@end

@implementation TCRingBuffer
@synthesize storage = _storage;
@synthesize capacity = _capacity;
@synthesize start, end;
@synthesize readCondition, writeCondition;

-(id)initWithCapacity:(NSUInteger)capacity;
{
    self.capacity = capacity;
    
    writeCondition = [NSCondition new]; 
    readCondition = [NSCondition new];
    
    return self;
}
-(NSUInteger)capacity;
{
    return _capacity;
}
-(void)setCapacity:(NSUInteger)capacity;
{
    _capacity = capacity;
    self.storage = [NSMutableData dataWithLength:capacity];
    [self reset];
}
-(void)dealloc;
{
    self.storage = nil;
    self.writeCondition = self.readCondition = nil;
}
-(void)getBytes:(char*)bytes ofLength:(NSUInteger)length;
{
    NSAssert(length < _capacity, @"will block forever");
    
    [readCondition lock];
    while(({
        BOOL notEnoughData = YES;
        @synchronized(_storage) {
            NSInteger aEnd = end;
            if(aEnd < start) aEnd += _capacity;
            notEnoughData = start + length > aEnd;
        }
        notEnoughData;
    }))
        [readCondition wait];
    
    @synchronized(_storage) {
        NSRange r = NSMakeRange(start, length);
        if(NSMaxRange(r) >= _storage.length)
            r.length = _storage.length - r.location;
        
        [_storage getBytes:bytes range:r];
        bytes += r.length;
        
        if(r.length < length) {
            r.location = 0;
            r.length = length - r.length;
            [_storage getBytes:bytes range:r];
        }
        start = NSMaxRange(r);
    }
    
    
    [writeCondition signal];
    [readCondition unlock];
}
-(void)writeBytes:(const char*)bytes ofLength:(NSUInteger)length;
{
    NSAssert(length < _capacity, @"will block forever");
    
    [writeCondition lock];
    
    while(({
        BOOL willNotFit = YES;
        @synchronized(_storage) {
            NSInteger aStart = start;
            if(aStart <= end) aStart += _capacity;
            willNotFit = end + length > (aStart - 1);
        }
        willNotFit;
    }))
        [writeCondition wait];
    
    @synchronized(_storage) {
        NSRange r = NSMakeRange(end, length);
        if(NSMaxRange(r) >= _storage.length)
            r.length = _storage.length - r.location;
        
        [_storage replaceBytesInRange:r withBytes:bytes];
        bytes += r.length;
        
        if(r.length < length) {
            r.location = 0;
            r.length = length - r.length;
            [_storage replaceBytesInRange:r withBytes:bytes];
        }
        end = NSMaxRange(r);
    }
    
    [readCondition signal];
    [writeCondition unlock];
}
-(void)reset;
{
    @synchronized(_storage) {
        start = end = 0;
    }
    [readCondition signal];
    [writeCondition signal];
}
@end
