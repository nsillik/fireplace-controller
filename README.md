# Nick's Fireplace Controller Thingy

## Why did you make this?

In 2022 we bought an _old_ house. A big ol' victorian built in 1891 which had been converted to a triplex. Unfortunately during this conversion they ripped out all 8 or so original fireplaces an bricked them up. Lame. So, we though we'd put in some gas fireplaces. We did! Then we needed a way to control them, so we bought this amazing remote control system for $500 each:

![Look at this garbage, just embarrasing](/static/lookAtThisJunk.png)

Yes, that's a resistive touch screen. Yes, it really is that ugly and clunky. Yes it did somehow cost $500 dollars. No, that is not my hand. It also does all sorts of annoying things, like only allow you to adust the time by one minute, so if you want to run your fireplace for 2 hours, have fun hitting the (again, resistive) "add minute" button _one hundred and twenty times_.

I hated this, my wife ([@jensillik](https://github.com/jensillik)) hated it, so we decided to do something about it. And here it is.

## How did you make it?

Well, like every computer person of a certain age, I have a giant pile of electronics, raspberry pis, arduinos, ESP8266s, ESP32s, PICs, PIDs, and whatnot lying around that I always pretended I would do something useful with. Mostly I would make an LED blink every few seconds, or say "I'm going to build a robot" and then… make an LED blink every few seconds.

So I gathered up some of my bits and bobs – namely an ESP32, a breadboard, some resistors, a relay, and _of course_ some LEDs for blinking – and slapped them together into some configuration that I was pretty sure would actually control the fireplace's electronics. Then I wrote some firmware code in ESP-IDF that actually turns on and off the relay (_and_ blinks LEDs). I wrote an iOS app (that was ugly), then Jen made some beautiful Figma designs, and so I made the app pretty! Finally I (tried) to build the schematics and PCB layouts for eventual actual-production of hardware!

That all became the following three things:

- *Flicker*: the firmware running on an ESP32 which handles wifi networking, a custom UDP protocol for remote control, and hareware control of the relay for turning the fireplace on and off.

- *Flame*: an iOS app, written in SwiftUI, for the users (all two of us) to control the fireplaces and view their statuses.

- *Spark*: a [KiCad](https://www.kicad.org/) project with schematics, BOM, and PCB layout for eventually actually manufacturing a good looking piece of hardware instead of a breadboard shoved under the fireplace.

Read on for details of all three

### ⚡️ Flicker - ESP32 Firmware

If you're in to electronics projects and somehow haven't heard of the [ESP32](https://www.espressif.com/en/products/socs/esp32), you're missing out. What a cool little chip! It's got:

- A dual core processor!
- 520KB of RAM!
- 448KB of ROM!
- WiFi (802.11 b/g/n)!
- Bluetooth (including BLE)!
- Tons of GPIO, ADCs, DACs, SPI, I2S, I2C, and more!

And it costs something like $6 for a devevelopment board!

For this project it's probably a bit of overkill, of course, since I'm using exactly _one_ GPIO. But the WiFi is _way_ easier – and cheaper – to get up and running than screwing around with an Arduino and some sort of shield. Also I had like 10 of them in a drawer, so why not?

When programming the ESP32 you can either use the Arduino SDK that everyone knows and loves, or Expressif's [ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/). I've done a bunch of things (like… making LEDs blink _a lot_) in Arduino, so I decided to use ESP-IDF just for fun.

For development I used [VSCode](https://code.visualstudio.com/) and the [PlatformIO](https://platformio.org/) extension which has boards and extensions and libraries and whatnot for the ESP32.

There's really only three interesting pieces of the code:

- The communcation protocol handler
- The wifi code
- The main app that ties it all together

I won't talk much about the last two, as they're pretty much just copies of the reference implementations for each from Expressif's docs with some things hardcoded for my network, like my WPA2 key (please don't hack me).

The communications handler (in [`/flicker/src/listener.c`](/flicker/src/listener.c)) is fun, and has a good description of the custom protocol in it. Here's how it works:

`udp_server_task` is a function that you pass to [FreeRTOS's](https://www.freertos.org/index.html) [`xTaskCreate`](https://www.freertos.org/a00125.html). This creates a task which FreeRTOS will schedule (somehow! I've not dug too deep into the guts).

This `udp_server_task` then binds a UDP (`SOCK_DGRAM`) listener on port `42069` (sorry, sorry, I'm trying to delete it), and then just busyloops listening for any messages. "Messages" here are just a super-simple protocol:

```
// 
// Command structure:
// Clients send commands in the following format:
// 0000 0000 0000 0000
// ^^|---------------|
// ||        | 
// ||        \--------> For command `10` The amount of time, in seconds to turn on for (for turn on command). Otherwise unused (zero is recommended)
// ||  
// \\-----------------> The command to send `00` for turn off, `01` for status, `10` for turn on
// 
// Server always replies with its status, either:
//  - `0000 0000 0000 0000` for off
//  - `10XX XXXX XXXX XXXX` for on, with the Xs being the time remaining in seconds
```

Basically a client can do three things:
- Send `0x4000`, requesting the status
- Send `0x8000 | (0x3FFF & 0xXXXX)` to turn the fireplace on for `XXXX` seconds (well, with the top two bits masked off)
- Send `0x0000` to turn the fireplace off.

When the server recieves these from the clients it updates it's current status which is just a shared (kinda gross, I know) `uint16_t`, and then sends the current (or updated) status back to the client.

There's another FreeRTOS task in `listener.c` called `statusLoop` which, every second, takes a look at the current status, and makes sure that the hardware is doing the right thing. That is:

- If the current status is `on`, decrement the time remaining by one second, and if it's now zero set the status to `off`.
- If the current status if `on`, and there's time remaining, make sure the `RELAY_PIN` is set to on. This closes the relay and the fireplace turns – or stays – on fire.
- If the current status is `off`, open the relay thereby turning the fireplace off, extinguishing the flame.

That's about it!

You'll see how this is all hooked up in [`flicker/src/main.c`](/flicker/src/main.c), which only does three things:

1. Sets up the networking (lines 12-21)
2. Schedules the two tasks above (lines 22 and 23).

That's it! Now we're ready for a client to actually start talking to it.

### 🔥 Flame - iOS App

And this is that client. An iOS app, written in SwiftUI, designed by the wonderul Jen Sillik. Here's the design:

![A screenshot of Figma showing designs for the iOS app](/static/prettyFigmaScreenshots.png)

There's only a few big pieces here:

- A `FireplaceService` which handles communication with the `Flicker` controller, as well as a test version for using in Xcode Previews.
- A `MainScreen` which is 100% of the UI and logic.
- A couple views like the custom `Picker`, the `GlassButtonStyle`, and the pretty `BackgroundView`.

#### `FireplaceService`

The [`FireplaceService`](/flame/flame/Services/FireplaceService.swift) is really the heart of the application. It's a reasonably simple protocol to conform to:

```swift
protocol FireplaceService: ObservableObject {
  var fireplaces: [Fireplace] { get }
  func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async -> Fireplace
  func turnOffFireplace(_ fireplace: Fireplace) async -> Fireplace
}
```

You can get a list of fireplaces. You can turn on the fireplace. You can turn off the fireplace. Not really much else to do! The `LiveFireplaceService` implements the real-for-real version of this which connects to the fireplaces in my house. The IP addresses are hardcoded, since I have my DHCP server always assign the same IP to the devices (because I'm lazy and didn't feel like doing mDNS in ESP-IDF, maybe some day).

Basically when this guy is `init`-ed it connects to all of the hardcoded fireplaces, gets their status, and then sets a timer to check on the status of the fireplaces every 20 seconds (I had it doing it every 200ms, but that was silly!). This is all done using the built in [`NWConnection`](https://developer.apple.com/documentation/network/nwconnection) which is pretty straightforward.

The connecting happens in the `connectTo` function which is pretty boring boilerplate, so I'm not going to say anymore about that.

The `requestStatus(fireplace:, connection:)` method sends the status message (`0x4000`), and that's it. Messages recieved _from_ the `Flicker` controllers are handled by the `receive(fireplace:, connection:)` method, and literally just update our internal list of fireplaces.

The `turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16)` and `turnOffFireplace(_ fireplace:)` methods just send the corresponding commands to the specified `Fireplace`. Easy-peasy.

Alllll of this is then injected into the SwiftUI Environment as an `EnvironmentObject` as a lazy-man's form of dependency injection.

#### `MainScreen`

The [`MainScreen`](/flame/flame/MainScreen.swift) is the only screen in the app (if only every app was just a single screen…), it's got a `FireplaceService` that it gets like so:
```swift
@EnvironmentObject var fireplaceService
```

And it keeps its state updated based on the currently selected fireplace (and that fireplaces current state). And then (depending on the current state), it has buttons to turn on, turn off, and adjust the time of the current selected fireplace.

#### Some rando views

There's a couple views in here too, but they're not to interesting. Quickly:

- [`Picker`](/flame/flame/Views/Picker.swift): is just a custom little picker view to match Jen's designs. You give it `options`, and it has a `@Binding` for the currently selected option. Neato!
- [`GlassButton`](/flame/flame/Views/GlassButton.swift): is a custom `ButtonStyle` for making the glassy looking buttons. There's actually a little bug here, but I haven't got a chance to sit down w/ my fantastic designer to work them out. It's good enough for now!
- [`BackgroundView`](/flame/flame/Views/BackgroundView.swift): is the pretty view that's the background of the whole app. It's a steely blue-gray color when the fireplace is off, and a warm orange-yellow color when the fireplace is on. Eventually I'm going to make this pretty and feel more alive.

#### That's it

Yeah, really. That's the whole app

### ✨ Spark - Hardware Design

As an added challenge I am trying to actually get the hardware manufactured. I haven't done it yet, and it'll probably be a disaster, but you can take a look at my attempts!

I'm using [KiCad](https://www.kicad.org/), a free and open-source EDA tool. To start, I needed to build a schematic. I used the [ESP32-DevKitC V4](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/hw-reference/esp32/get-started-devkitc.html) as my starting guide. This includes:

- The ESP32
- A usb connector
- A [`CP2102N`](https://www.silabs.com/documents/public/data-sheets/cp2102n-datasheet.pdf) USB-to-UART controller for serial access
- An [`AS1117`](http://www.advanced-monolithic.com/pdf/ds1117.pdf) voltage regulator for going from USBs 5v to the 3.3v that the ESP32 runs on.
- A few buttons, transistors, caps, resistors, diodes, and – of course – blinking LEDs.

On top of that I added a [SRD-03VDC-SL-C](https://pdf1.alldatasheet.com/datasheet-pdf/view/1132027/SONGLERELAY/SRD-03VDC-SL-C.html) relay for actually controlling the fireplace. Oh yeah, and there's some transistors and resistors and diodes around the relay so that it… relays correctly? IDK 🤷‍♀️

I laid that all out in the schematic editor – mostly according to datasheets, example circuits, and with the help of a few buddies – and it ended up looking like this:

![A schematic, there's a lot going on here](/static/aSchematicNeat.png)

After that I had to put together the BOM and footprints (although, I'm pretty sure I got some wrong, will be doing like 10 more reviews before ordering):

![Footprint pic](/static/footprintPic.png)

And then, for the hard part, laying out a PCB. Okay, I'm terrible at this, and this was like my 12th attempt. I got everything hooked up, but it's still _really ugly_. It looks like this:

![Just the sloppiest PCB layout you've ever seen. I'm sorry](/static/messyPCB.png)

And, one day, when I send it to [JLCPCB](https://jlcpcb.com/) for assembly, it'll end up looking something like this:

![A 3d rending of the PCB… uhhh… I think that diode looks to big, hm, probably going to have to fix that ](/static/theThirdDimension.png)

### ✍️ What's left to do?

Does it work? Yes! Am I done? Probably not. There's a few more things I'd like to do, most of which I mentioned above:

- Prettier animations in the app! Especially making the background feel a bit more alive.
- Fixing the `GlassButtonStyle` to not be kinda-wrong at times
- Reviewing and checking the schematics (and trying to force friends to do the same) to spot any bugs.
- Probably re-laying out the PCB another 15 or so times until I'm happy with it. It's a bit bigger than I'd like it to be. Maybe I can find a smaller relay?

### 🧨 Is this safe?

God, I hope so 😬

### That's it

If you read this far, sorry! Hope you learned something, even if that something was "don't hire @nsillik for electrical engineering!".