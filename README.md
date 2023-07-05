# USB-Stepper-Control (and Rotary Pen Table Project)

A set of tools to provide simple control of a stepper from a PC USB Interface (Bridge: PC USB to AccelStepper Arduino Library)

The USB Stepper Control project provides direct control of stepper motors via a USB Connection to a PC.  This enables extended functionality for devices to be controlled via user interfaces or events directly from a Windows PC.  This project also includes the necessary 3D print files, parts list, and wiring diagrams to create a fully functional Rotary Pen Table for laser etching pens.  (The Rotary Table was the driving goal for this project!)

The Physical Connections are as follows:

     PC USB Serial Connection -> Microcontroller (ESP32, Arduino, etc) -> Stepper Driver -> Stepper Motor

The Logical Functionality is as follows:

     PC Interface (AutoIT) -> Microcontroller Control Software (ESP32, Arduino, etc) -> AccelStepper Arduino Library

There are two parts to this project:

1.  Microcontoller Side:  The microcontroller side utilizes the popular "AccelStepper" library to control a stepper driver/motor.  The AccelStepper library functions are effectively abstracted over a USB Serial interface.  A serial handshaking protocol is used to pass commands to the microcontroller (Arduino, ESP32, etc).  Both blocking and non-blocking functions are supported.  Basically, all "AccelStepper" functions are implemented and supported by passing serial commands directly over the usb interface with the appropriate number of parameters.  The Microcontroller side is simply used to objectify the library and once uploaded, very little ongoing maintenance should be required in order to maintain the microcontroller side as projects are added or updated on the PC Side.  (IOW: Functional logic can be entirely implemented/maintained on the PC side)  The microcontroller side should be largely static unless changes are required to support additional updates to the AccelStepper Library.

2.  PC Side: The PC side exposes the "AccelStepper" function calls over the USB Serial Interface.  The actual function call is implemented as the first field in the serial command with additional fields provided for each of the required function parameters.  This effectively allows AccelStepper library functions to be directly called from a PC Application.  

Once the Microcontroller code (USBStepperCtl.ino)is compiled and uploaded (to Arduino, ESP32, etc) then the PC Side (AutoIT) can be used to control the associated stepper.  Example code is provided using the AutoIT development environment (free).  (AutoIT excels in the simplicity of user interface creation, scripts can be compiled into standalone executables, and the development environment is freely available). The following example code fully implements the command construction and handshaking as required to implement the associated protocol.

PC (AutoIT) Examples:

USBStepperCtl.au3:  This is a very simply script demonstrating three different ways to move a stepper between various positions.  The associated INI file (of the same name) can be used to configure the operation of the program.  The [Config] section is used to define the COM Port where the stepper controller is connected, which demo program is to be run (RunDemo=Demo1, Demo2, or Demo3).  It also supports the ability to specify/maintain specific configuration parameters within separate INI sections (RunConfig=).  "MinPulseWidth" is also supported which is reportedly required for TB6600 Stepper Drivers.  The USBStepperCtl example provides no user interface and will simply run until the process is manually terminated.

Indexer.au3:  Is a sample utility developed to drive a rotary "Pen Table" for engaving using a Galvo Laser.  The format of the INI file is much like that used for USBStepperCtl example (above).The "RunConfig" option is used to designate a section which defines the stepper driver configuration parameters.  The Indexer example user interface supports initial adjustment/alignment of the rotary table (Tweak), an indexing function, the ability to disable/enable the stepper motor (for manual rotation or power savings), and a QUIT function.  Additionally, The Indexer utility (once compiled) can be called directly from the command line to control the rotary table using the command line parameters of "CW" (clockwise) or "CCW" (counter-clockwise) for rotation.  For example: Launch INDEXER.EXE, manually rotate the pen table to the desired position, "Enable" the stepper motor to grab the position, and then "Tweak" the rotation if needed to further adjust the position.  Then just call "Indexer CCW" or "Indexer CW" from your application as needed to precisely rotate the table

Through examination of both examples, it should be quite easy to duplicate the necessary code to implement a PC side control application as desired for a wide variety of applications.  

*** We have asked the developers at Lightburn to provide a "Before Job" and "After Job" command line option such that "Indexer" can be to control a virtually unlimited array of user developed solutions.

>--------------------------------------------------------------------------------

Rotary Pen Table Project:

This project consists of the following components:

- 3D Print File (STL) to create the Pen Wheel (in 4 quadrants): Pen_Wheel_Quarter.stl
- Acrylic Cut File (DXF) to create the foundation to which the Pen Wheel Quadrants are mounted: Pen_Wheel_Foundation.dxf
- 3D Print Files (STL) to create the Enclosure which holds the print wheel and ALL its components (Stepper, Driver, ESP32 Controller, Cooling Fan): Combined_Enclosure_Bottom.stl, Combined_Enclosure_Top.stl

...and if you would like to "split" the stepper motor from the control unit, here is another set of files.  The stepper "control" housing can then be used with ANY stepper (i.e. Rotary Chuck) which uses a standard 4-connector GX-16 aviation connector:

- 3D Print Files (STL) to create an Enclosure for JUST the controller components (without Stepper): Control_Enclosure_Bottom.stl, Control_Enclosure_Top.stl
- 3D Print Files (STL) to create an Enclosure for JUST the stepper iteself (without Driver, ESP32, or Cooling Fan): Stepper_Enclosure_Bottom.stl, Stepper_Enclosure_Top.stl

Parts List (about $65)

- ESP32 ($6): https://www.amazon.com/gp/product/B09GK74F7N
- Nema23 Stepper ($26):  https://www.amazon.com/dp/B00PNEPF5I
- TB6600 Driver ($10): https://www.amazon.com/dp/B07PQ5KNKR
- 12v 4A Power Supply ($13): https://www.amazon.com/dp/B07H493GHX
- Power Jack ($2): https://www.amazon.com/dp/B08SJM2G52
- 6.35mm Flange Coupling ($2): https://www.amazon.com/dp/B08334YZ9V
- 40mm 12v Fan ($3): https://www.amazon.com/dp/B07CH6YC32
- Fan Cover ($2): https://www.amazon.com/dp/B00E1LAWHA
- (For "split" housing) GX-16 Stepper Connector ($2): https://www.amazon.com/gp/product/B07D3DC1PD

A wiring Schematic for the "combined" enclosure is provided: Controller_Schematic.jpg

Photos of the various components (combined and seperate) are also provided

Project Notes

- An ESP32 microcontroller is used because of its small size, inexpensive cost, and powerful architecture.
- A TB6600 Stepper Driver is used as it is relatively inexpensive and provides very good control of our Nema23 stepper
- A 4A 12V power supply is used to provide higher power (4A) to maximize control (microstepping) and holding power of the stepper
- A fan, and colling vents in the enclosure, is used to maintain temps while operating

Assembly Notes

- Lightly coating the "holding slots" of the fully assembled pen wheel wiuth PlastiDip (or similar) will help minimize pen movement during rotation.  A small paint brush can be used to coat the slots to provide a very thin, rubberized, non-slip surface.

- An Adhesive Neoprene Pad cut to fit the bottom of the enclosure will help keep the device in place during operation
