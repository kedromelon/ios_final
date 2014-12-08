//
//  GameScene.m
//  basketclimb
//
//  Created by Noah Lemen on 11/11/14.
//  Copyright (c) 2014 nyu.edu. All rights reserved.
//

#import "GameScene.h"
#import "Map.h"

const float FORCE_MULT = 1.5;
const float MIN_INPUT = 35.0;
const float SWIPE_FORCE = 2.0;

@interface GameScene() <SKPhysicsContactDelegate>

@end

@implementation GameScene
{
    CGPoint touchBegan;
    CGPoint touchEnd;
    SKShapeNode *touchline;
    SKShapeNode *touchline2;
    float basketHeight;
    BOOL canShoot;
    BOOL canSwipe;
}

-(id)initWithSize:(CGSize)size {
    if(self = [super initWithSize:size]){
        // Set background color and gravity
        self.backgroundColor = [SKColor colorWithRed:0.769 green:0.945 blue:1.0 alpha:1.0];
        self.physicsWorld.gravity = CGVectorMake(0.0f, -9.8f);
        
        // Add node for game world
        self.world = [SKNode node];
        
        // Initialize and set-up the map node
        self.map = [[Map alloc] init];
        
        self.camera = [SKNode node];
        self.camera.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        
        // Create ball
        self.ball = [[Ball alloc] init];
        self.ball.xScale = .25;
        self.ball.yScale = .25;
        self.ball.name = @"ball";
        self.ball.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self.world addChild:self.ball];
        self.ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.ball.frame.size.width/2.5];
        self.ball.physicsBody.allowsRotation = NO;
        self.ball.physicsBody.categoryBitMask = CollisionTypeBall;
        self.ball.physicsBody.contactTestBitMask = CollisionTypeBasket;
        
        [self.world addChild:self.map];
        [self.world addChild:self.camera];
        [self addChild:self.world];
        
        self.anchorPoint = CGPointMake(.5, .5);
        
        [self centerOnNode:self.camera];
        
        self.physicsWorld.contactDelegate = self;
        
    }
    return self;
}



-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    canShoot = [self.ball isResting] ? YES : NO;
    
    UITouch *touch = [touches anyObject];
    touchBegan = [touch locationInNode:self];
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInNode:self];
    
    if (canSwipe) {
        GLKVector2 direction = GLKVector2Normalize(GLKVector2Make(touchPoint.x - touchBegan.x, touchPoint.y - touchBegan.y));
        GLKVector2 force = GLKVector2MultiplyScalar(direction, SWIPE_FORCE);
        if (direction.y <= 0) self.ball.physicsBody.velocity = CGVectorMake(0, 0);
        [self.ball.physicsBody applyImpulse:CGVectorMake(force.x, force.y)];
        canSwipe = NO;
        return;
    }
    else if (!canShoot) return;
    

    [touchline removeFromParent];
    [touchline2 removeFromParent];
    [[self childNodeWithName:@"arrow"] removeFromParent];
    
    float distance = [self distanceFrom:touchBegan to:touchPoint];
    
    if (distance > MIN_INPUT){
        
        distance = (distance > self.frame.size.height/3) ? self.frame.size.height/3 : distance;
        
        SKSpriteNode *arrow = [SKSpriteNode spriteNodeWithImageNamed:@"arrow"];
        
        GLKVector2 direction = GLKVector2Normalize(GLKVector2Make(touchPoint.x - touchBegan.x, touchPoint.y - touchBegan.y));
        GLKVector2 frontLineBegin =  GLKVector2Subtract(GLKVector2Make(touchBegan.x, touchBegan.y), GLKVector2MultiplyScalar(direction, MIN_INPUT-20));
        GLKVector2 backLineBegin = GLKVector2Add(GLKVector2Make(touchBegan.x, touchBegan.y), GLKVector2MultiplyScalar(direction, MIN_INPUT-20));
        
        CGMutablePathRef pathToDraw = CGPathCreateMutable();
        CGPathMoveToPoint(pathToDraw, NULL, frontLineBegin.x, frontLineBegin.y);
        GLKVector2 frontLineEnd = GLKVector2Add(GLKVector2Make(touchBegan.x, touchBegan.y), GLKVector2MultiplyScalar(direction, -distance));
        CGPathAddLineToPoint(pathToDraw, NULL, frontLineEnd.x, frontLineEnd.y);
        CGPathCloseSubpath(pathToDraw);
        
        CGMutablePathRef pathToDraw2 = CGPathCreateMutable();
        CGPathMoveToPoint(pathToDraw2, NULL, backLineBegin.x, backLineBegin.y);
        GLKVector2 backLineEnd = GLKVector2Add(GLKVector2Make(touchBegan.x, touchBegan.y), GLKVector2MultiplyScalar(direction, distance));
        CGPathAddLineToPoint(pathToDraw2, NULL, backLineEnd.x, backLineEnd.y);
        CGPathCloseSubpath(pathToDraw2);
        
        touchline = [SKShapeNode node];
        touchline.lineWidth = 1;
        touchline.path = pathToDraw;
        CGPathRelease(pathToDraw);
        [touchline setStrokeColor:[UIColor blackColor]];
        [self addChild:touchline];
        
        touchline2 = [SKShapeNode node];
        touchline2.path = pathToDraw2;
        CGPathRelease(pathToDraw2);
        [touchline2 setStrokeColor:[UIColor colorWithWhite:0 alpha:.1]];
        [self addChild:touchline2];
        
        arrow.position = CGPointMake(frontLineEnd.x,
                                    frontLineEnd.y);
        arrow.xScale = .5f;
        arrow.yScale = .5f;
        arrow.zRotation = atan2f(direction.y, direction.x);
        
        arrow.name = @"arrow";
        [self addChild:arrow];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (!canShoot) return;
    
    [touchline removeFromParent];
    [touchline2 removeFromParent];
    [[self childNodeWithName:@"arrow"] removeFromParent];
    
    UITouch *touch = [touches anyObject];
    touchEnd = [touch locationInNode:self];
    
    float distance = [self distanceFrom:touchBegan to:touchEnd];
    if (distance > MIN_INPUT){
        distance = (distance > self.frame.size.height/3) ? self.frame.size.height/3 : distance;
        GLKVector2 direction = GLKVector2Normalize(GLKVector2Make(touchEnd.x - touchBegan.x, touchEnd.y - touchBegan.y));
        float magnitude = -FORCE_MULT * powf(distance,.3);
        GLKVector2 force = GLKVector2MultiplyScalar(direction, magnitude);
        [self.ball.physicsBody applyImpulse:CGVectorMake(force.x, force.y)];
        canSwipe = YES;
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if ([self.ball isResting]){
        canSwipe = NO;
        // go above ball if its resting
        float ydistance = self.ball.position.y - self.camera.position.y + self.frame.size.height*.45;
        self.camera.position = CGPointMake(self.camera.position.x, (float)MAX(self.camera.position.y + ydistance *.1, self.frame.size.height/2));
    }else{
        float ydistance = self.ball.position.y - self.camera.position.y;
        float distanceFromRest = self.ball.position.y - self.ball.lastRestingPosition.y;
        if (fabsf(ydistance) > self.frame.size.height/3
            && ((distanceFromRest > self.frame.size.height/3 && self.ball.physicsBody.velocity.dy > 0)
                || (self.ball.physicsBody.velocity.dy < 0))){
            self.camera.position = CGPointMake(self.camera.position.x, (float)MAX(self.camera.position.y + ydistance *.05, self.frame.size.height/2));
        }
    }

}

-(void)didFinishUpdate{
    [self centerOnNode: self.camera];
}

-(float)distanceFrom:(CGPoint)from to:(CGPoint)to{
    float dx = to.x - from.x;
    float dy = to.y - from.y;
    return sqrtf(dx*dx + dy*dy);
}

-(void)didSimulatePhysics{
    
}

-(void) centerOnNode:(SKNode *)node{
    CGPoint cameraPositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
    node.parent.position = CGPointMake(node.parent.position.x - cameraPositionInScene.x, node.parent.position.y - cameraPositionInScene.y);
}


-(void)extendMap
{
    // call 
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    // Set bodies
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // IF one body is the basket and the other is the ball, do something
    if ((firstBody.categoryBitMask & CollisionTypeBasket) != 0 && (secondBody.categoryBitMask & CollisionTypeBall) != 0)
    {
        NSLog(@"Basket made");
        self.ball.touchingBasket = YES;
        
        //NSLog(@"Basket Made");
    }
}

-(void)didEndContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    // Set bodies
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // IF one body is the basket and the other is the ball, do something
    if ((firstBody.categoryBitMask & CollisionTypeBasket) != 0 && (secondBody.categoryBitMask & CollisionTypeBall) != 0)
    {
        NSLog(@"Contact ended");
        self.ball.touchingBasket = NO;
    }
}

@end
