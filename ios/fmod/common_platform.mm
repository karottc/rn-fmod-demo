#import "common.h"
#import <Foundation/NSString.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioSession.h>
#import <GameController/GameController.h>

const Common_Button BTN_IDS[] = {BTN_ACTION1, BTN_UP, BTN_ACTION2, BTN_LEFT, BTN_MORE, BTN_RIGHT, BTN_ACTION3, BTN_DOWN, BTN_ACTION4};
const unsigned int BTN_COUNT = sizeof(BTN_IDS) / sizeof(BTN_IDS[0]);
const unsigned int BTN_COUNT_PER_ROW = 3;
/*
@interface ViewController : UIViewController
    @property (strong, nonatomic) UILabel *textDisplay;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
    @property (strong, nonatomic) UIWindow *window;
    @property (strong, nonatomic) ViewController *viewController;
@end
*/
NSMutableString *gOutputBuffer = nil;
uint32_t gActions = 0;
uint32_t gButtons = 0;
uint32_t gButtonsDown = 0;
uint32_t gButtonsPress = 0;
GCGamepad *gGamePad = nil;
void (*gSuspendCallback)(bool suspend);

void Common_RegisterSuspendCallback(void (*callback)(bool))
{
    gSuspendCallback = callback;
}

void Common_Init(void **extraDriverData)
{
    /*
        Optimize audio session for FMOD defaults
    */
    double rate = 24000.0;
    int blockSize = 512;
    long channels = 2;
    BOOL success = false;
    AVAudioSession *session = [AVAudioSession sharedInstance];

    // Make our category 'solo' for the best chance at getting our desired settings
    // Use AVAudioSessionCategoryPlayAndRecord if you need microphone input
    success = [session setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    assert(success);
    
    // Set our preferred rate and activate the session to test it
    success = [session setPreferredSampleRate:rate error:nil];
    assert(success);
    success = [session setActive:TRUE error:nil];
    assert(success);
    
    // Query the actual supported rate and max channels
    rate = [session sampleRate];
    channels = [session respondsToSelector:@selector(maximumOutputNumberOfChannels)] ? [session maximumOutputNumberOfChannels] : 2;
    
    // Deactivate the session so we can change parameters without route changes each time
    success = [session setActive:FALSE error:nil];
    assert(success);
    
    // Set the duration and channels based on known supported values
    success = [session setPreferredIOBufferDuration:blockSize / rate error:nil];
    assert(success);
    if ([session respondsToSelector:@selector(setPreferredOutputNumberOfChannels:error:)])
    {
        success = [session setPreferredOutputNumberOfChannels:channels error:nil];
        assert(success);
    }
    
    /*
        Set up some observers for various notifications
    */
    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
    {
        bool began = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue] == AVAudioSessionInterruptionTypeBegan;
        NSLog(@"Interruption %@", began ? @"Began" : @"Ended");
        
        if (!began)
        {
            [[AVAudioSession sharedInstance] setActive:TRUE error:nil];
        }
        
        if (gSuspendCallback)
        {
            gSuspendCallback(began);
        }
    }];

    if (&AVAudioSessionSilenceSecondaryAudioHintNotification)
    {
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
        {
            bool began = [[notification.userInfo valueForKey:AVAudioSessionSilenceSecondaryAudioHintTypeKey] intValue] == AVAudioSessionSilenceSecondaryAudioHintTypeBegin;
            NSLog(@"Silence secondary audio %@", began ? @"Began" : @"Ended");
        }];
    }

    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
    {
        NSNumber *reason = [[notification userInfo] valueForKey:AVAudioSessionRouteChangeReasonKey];
        AVAudioSessionPortDescription *oldOutput = [[[notification userInfo] valueForKey:AVAudioSessionRouteChangePreviousRouteKey] outputs][0];
        AVAudioSessionPortDescription *newOutput = [[[AVAudioSession sharedInstance] currentRoute] outputs][0];

        const char *reasonString = NULL;
        switch ([reason intValue])
        {
            case AVAudioSessionRouteChangeReasonNewDeviceAvailable:         reasonString = "New Device Available";              break;
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:       reasonString = "Old Device Unavailable";            break;
            case AVAudioSessionRouteChangeReasonCategoryChange:             reasonString = "Category Change";                   break;
            case AVAudioSessionRouteChangeReasonOverride:                   reasonString = "Override";                          break;
            case AVAudioSessionRouteChangeReasonWakeFromSleep:              reasonString = "Wake From Sleep";                   break;
            case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory: reasonString = "No Suitable Route For Category";    break;
            case AVAudioSessionRouteChangeReasonRouteConfigurationChange:   reasonString = "Configuration Change";              break;
            default:                                                        reasonString = "Unknown";
        }

        NSLog(@"Output route has changed from %dch %@ to %dch %@ due to '%s'", (int)[[oldOutput channels] count], [oldOutput portName], (int)[[newOutput channels] count], [newOutput portName], reasonString);
    }];

    if (&AVAudioSessionMediaServicesWereLostNotification)
    {
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionMediaServicesWereLostNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
        {
            NSLog(@"Media services were lost");
        }];
    }
    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionMediaServicesWereResetNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
    {
        NSLog(@"Media services were reset");
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
    {
        NSLog(@"Application did become active");
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
    {
        NSLog(@"Application will resign active");
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
    {
        NSLog(@"Application did enter background");
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
    {
        NSLog(@"Application will enter foreground");
    }];


    /*
        Activate the audio session
    */
    success = [session setActive:TRUE error:nil];
    assert(success);

    /*
        Setup input and output state
    */
    gOutputBuffer = [NSMutableString stringWithCapacity:(NUM_COLUMNS * NUM_ROWS)];
    
    for (GCController *gc in [GCController controllers])
    {
        gGamePad = [gc gamepad];
        if (gGamePad)
        {
            break;
        }
    }
}

void Common_Close()
{

}
/*
void Common_Update()
{
    ViewController *controller = (ViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    [controller performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:YES];
    
    if (gGamePad)
    {
        if ([[gGamePad buttonA] isPressed])         gButtons |=  (1 << BTN_ACTION1);
        else                                        gButtons &= ~(1 << BTN_ACTION1);
        if ([[gGamePad buttonB] isPressed])         gButtons |=  (1 << BTN_ACTION2);
        else                                        gButtons &= ~(1 << BTN_ACTION2);
        if ([[gGamePad buttonX] isPressed])         gButtons |=  (1 << BTN_ACTION3);
        else                                        gButtons &= ~(1 << BTN_ACTION3);
        if ([[gGamePad buttonY] isPressed])         gButtons |=  (1 << BTN_ACTION4);
        else                                        gButtons &= ~(1 << BTN_ACTION4);
        
        if ([[[gGamePad dpad] up] isPressed])       gButtons |=  (1 << BTN_UP);
        else                                        gButtons &= ~(1 << BTN_UP);
        if ([[[gGamePad dpad] down] isPressed])     gButtons |=  (1 << BTN_DOWN);
        else                                        gButtons &= ~(1 << BTN_DOWN);
        if ([[[gGamePad dpad] left] isPressed])     gButtons |=  (1 << BTN_LEFT);
        else                                        gButtons &= ~(1 << BTN_LEFT);
        if ([[[gGamePad dpad] right] isPressed])    gButtons |=  (1 << BTN_RIGHT);
        else                                        gButtons &= ~(1 << BTN_RIGHT);
        
        if ([[gGamePad leftShoulder] isPressed])    gButtons |=  (1 << BTN_QUIT);
        else                                        gButtons &= ~(1 << BTN_QUIT);
        if ([[gGamePad rightShoulder] isPressed])   gButtons |=  (1 << BTN_MORE);
        else                                        gButtons &= ~(1 << BTN_MORE);
    }
}
*/
void Common_Sleep(unsigned int ms)
{
    [NSThread sleepForTimeInterval:(ms / 1000.0f)];
}

void Common_Exit(int returnCode)
{
    exit(-1);
}

void Common_DrawText(const char *text)
{   
    [gOutputBuffer appendFormat:@"%s\n", text];
}

bool Common_BtnPress(Common_Button btn)
{
    return ((gButtonsPress & (1 << btn)) != 0);
}

bool Common_BtnDown(Common_Button btn)
{
    return ((gButtonsDown & (1 << btn)) != 0);
}

const char *Common_BtnStr(Common_Button btn)
{
    switch (btn)
    {
        case BTN_ACTION1: return "A";
        case BTN_ACTION2: return "B";
        case BTN_ACTION3: return "X";
        case BTN_ACTION4: return "Y";
        case BTN_UP:      return "Up";
        case BTN_DOWN:    return "Down";
        case BTN_LEFT:    return "Left";
        case BTN_RIGHT:   return "Right";
        case BTN_MORE:    return gGamePad ? "Right Shoulder" : "E";
        case BTN_QUIT:    return gGamePad ? "Left Shoulder" : "Home";
    }
}

const char *Common_MediaPath(const char *fileName)
{
    return [[NSString stringWithFormat:@"%@/media/%s", [[NSBundle mainBundle] resourcePath], fileName] UTF8String];
}

void Common_LoadFileMemory(const char *name, void **buff, int *length)
{
    FILE *file = fopen(name, "rb");

    fseek(file, 0, SEEK_END);
    long len = ftell(file);
    fseek(file, 0, SEEK_SET);

    void *mem = malloc(len);
    fread(mem, 1, len, file);

    fclose(file);

    *buff = mem;
    *length = (int)len;
}

void Common_UnloadFileMemory(void *buff)
{
    free(buff);
}

/*
@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

    const CGRect appFrame = [[UIScreen mainScreen] bounds];
    [[UIScreen mainScreen] setOverscanCompensation:UIScreenOverscanCompensationInsetBounds];

    self.textDisplay = [[UILabel alloc] init];
    [self.textDisplay setNumberOfLines:0];
    [self.textDisplay setBackgroundColor:[UIColor blackColor]];
    [self.textDisplay setTextColor:[UIColor whiteColor]];
    [self.textDisplay setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:10]];

    [self.view addSubview:self.textDisplay];
    [self.view setBackgroundColor:[UIColor blackColor]];

    for (unsigned int i = 0; i < BTN_COUNT; i++)
    {
        const float BTN_SPACER = 2;
        const float BTN_WIDTH = (appFrame.size.width - ((BTN_COUNT_PER_ROW - 1) * BTN_SPACER)) / BTN_COUNT_PER_ROW;
        const float BTN_HEIGHT = 42; // iOS human interface guidelines minimum tappable size is 44x44
        const float BTN_X = (i % BTN_COUNT_PER_ROW) * (BTN_WIDTH + BTN_SPACER);
        const float BTN_Y = appFrame.size.height - (((BTN_COUNT / BTN_COUNT_PER_ROW) - (i / BTN_COUNT_PER_ROW)) * (BTN_HEIGHT + BTN_SPACER));

        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(BTN_X, BTN_Y, BTN_WIDTH, BTN_HEIGHT)];
        [button setTitle:[NSString stringWithUTF8String:Common_BtnStr(BTN_IDS[i])] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:134.0f/255.0f green:145.0f/255.0f blue:158.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:207.0f/255.0f green:188.0f/255.0f blue:105.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        [button setBackgroundColor:[UIColor colorWithRed:64.0f/255.0f green:85.0f/255.0f blue:90.0f/255.0f alpha:1.0f]];
        [button setTag:BTN_IDS[i]];
        [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside];
#if TARGET_OS_TV
        [button addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventPrimaryActionTriggered];
        [button setTitleColor:[UIColor colorWithRed:207.0f/255.0f green:188.0f/255.0f blue:105.0f/255.0f alpha:1.0f] forState:UIControlStateFocused];
#endif
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
        
        [self.view addSubview:button];
    }

    // Wait until the end of the run loop before kicking off our 'game' thread
    [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:FALSE];
}

- (UIView *)preferredFocusedView
{
    return self.view.subviews[1]; // 1 = first button, not text display
}

- (void)dealloc
{
}

- (void)start
{
    // Kick off the 'game' thread in the background, all initialization is complete now
    [self performSelectorInBackground:@selector(threadMain) withObject:nil];
}

- (void)update
{
    [self.textDisplay setText:gOutputBuffer];
    [self.textDisplay sizeToFit];
    [gOutputBuffer setString:@""];

    gButtonsPress = ((gButtonsDown ^ gButtons) & gButtons) | gActions;
    gButtonsDown = gButtons;
    gActions = 0;
}

int FMOD_Main();
- (void)threadMain
{
    @autoreleasepool
    {
        FMOD_Main();
    }
}

- (void)buttonDown:(id)sender
{
    gButtons |= (1 << [sender tag]);
}

- (void)buttonUp:(id)sender
{
    gButtons &= ~(1 << [sender tag]);
}

- (void)buttonPress:(id)sender
{
    gActions |= (1 << [sender tag]);
}
@end


@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[ViewController alloc] init];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)dealloc
{
    //[_window release];
    //[_viewController release];
    //[super dealloc];
}
@end


int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
*/
