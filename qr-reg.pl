#!/usr/bin/python
#################################################
#
# BSidesDC QR Code Reader Registration System
# Using a Raspberry Pi
#
# Version
# -----------------------------------------------
# 1.0	jdg	Initial Version (2016-09)
#
# Authors
# -----------------------------------------------
# jdg	Jim Gilsinn
#
#################################################

import sys, os, time, subprocess, numbers, logging
import RPi.GPIO as GPIO
import pygame, qrtools
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
import urllib3

#################################################

#------------------------------------------------
# Usage Message
#------------------------------------------------
usage = """
Usage:	qr-reg.py [demo_file]

Process QR codes generated by the BSidesDC
registration system.

demo_file	(optional) Process and display
		the desired demonstration file
"""

#------------------------------------------------
# Assign Values for LEDs
#------------------------------------------------
led_status_blue_gpio = 20
led_status_green_gpio = 21
led_code_red_gpio = 16
led_code_green_gpio = 12
led_on = GPIO.LOW
led_off = GPIO.HIGH

#------------------------------------------------
# Assign Values for QR Decoder
#------------------------------------------------
window_title = "BSidesDC Registration"
image_path = "/var/lib/motion"
window_size = (640,480)
full_window_size = (0,0,640,480)
image_size = (640,360)
image_offset = (0,120)
font_color = (255,255,0)
background_color = (0,0,0)
font_type = "monospace"
font_size = 15
qr_text_offset = (25,25)
server_text_offset = (25,75)
new_image_file = False
img_file = ""

#------------------------------------------------
# Assign Values for Different Timers
#------------------------------------------------
cycle_sleep_time = 0.1
blink_time = 0.5
status_display_time = 1.0

#################################################

#------------------------------------------------
# Function - Clear Status LED
#------------------------------------------------
def LEDStatusOff():
  GPIO.output(led_status_blue_gpio, led_off)
  GPIO.output(led_status_green_gpio, led_off)

#------------------------------------------------
# Function - Clear Code LED
#------------------------------------------------
def LEDCodeOff():
  GPIO.output(led_code_red_gpio, led_off)
  GPIO.output(led_code_green_gpio, led_off)

#------------------------------------------------
# Function - Clear All LEDs
#------------------------------------------------
def LEDAllOff():
  LEDStatusOff()
  LEDCodeOff()

#------------------------------------------------
# Function - Flash Status LED Blue
#------------------------------------------------
def LEDStatusFlashBlue(flash_time):
  GPIO.output(led_status_green_gpio,led_off)
  GPIO.output(led_status_blue_gpio,led_on)
  time.sleep(flash_time)
  GPIO.output(led_status_blue_gpio,led_off)
  time.sleep(flash_time)

#------------------------------------------------
# Function - Solid Status LED Blue
#------------------------------------------------
def LEDStatusSolidBlue():
  GPIO.output(led_status_green_gpio,led_off)
  GPIO.output(led_status_blue_gpio,led_on)

#------------------------------------------------
# Function - Solid Status LED Green
#------------------------------------------------
def LEDStatusSolidGreen():
  GPIO.output(led_status_blue_gpio,led_off)
  GPIO.output(led_status_green_gpio,led_on)

#------------------------------------------------
# Function - Flash Code LED Red
#------------------------------------------------
def LEDCodeFlashRed(flash_time):
  GPIO.output(led_code_green_gpio,led_off)
  GPIO.output(led_code_red_gpio,led_on)
  time.sleep(flash_time)
  GPIO.output(led_code_red_gpio,led_off)
  time.sleep(flash_time)

#------------------------------------------------
# Function - Solid Code LED Red
#------------------------------------------------
def LEDCodeSolidRed():
  GPIO.output(led_code_green_gpio,led_off)
  GPIO.output(led_code_red_gpio,led_on)

#------------------------------------------------
# Function - Solid Code LED Yellow
#------------------------------------------------
def LEDCodeSolidYellow():
  GPIO.output(led_code_green_gpio,led_on)
  GPIO.output(led_code_red_gpio,led_on)

#------------------------------------------------
# Function - Solid Code LED Green
#------------------------------------------------
def LEDCodeSolidGreen():
  GPIO.output(led_code_red_gpio,led_off)
  GPIO.output(led_code_green_gpio,led_on)

#------------------------------------------------
# Function - Initialize GPIO
#------------------------------------------------
def InitializeGPIO():
  GPIO.setmode(GPIO.BCM)
  GPIO.setup(led_status_blue_gpio, GPIO.OUT)
  GPIO.setup(led_status_green_gpio, GPIO.OUT)
  GPIO.setup(led_code_red_gpio, GPIO.OUT)
  GPIO.setup(led_code_green_gpio, GPIO.OUT)
  LEDAllOff()

#------------------------------------------------
# Function - Check That Motion Is Started
#------------------------------------------------
def CheckMotionStarted():
  motion_started = False
  while (motion_started == False):
    LEDStatusFlashBlue(blink_time)
    proc = subprocess.Popen(["pgrep","motion"],stdout=subprocess.PIPE)
    proc_out = proc.stdout.readline().strip()
    if proc_out != "":
      motion_started = True
      print "Camera Motion Detection Started."
    else:
      print "Waiting for Camera Motion Detection to Start..."

#################################################

#------------------------------------------------
# Class - New Image Event Handler
#------------------------------------------------
class NewFileEventHandler(PatternMatchingEventHandler):
  patterns = ["*.jpg", "*.jpeg"]

  def process(self, event):
    """
    event.event_type 
      'modified' | 'created' | 'moved' | 'deleted'
    event.is_directory
       True | False
    event.src_path
       path/to/observed/file
    """
    global new_image_file
    new_image_file = True
    global img_file
    img_file = event.src_path

  def on_created(self, event):
    self.process(event)

#################################################

#------------------------------------------------
# Check For a Demo Test File
#------------------------------------------------
demo_file = ""
if len(sys.argv) == 1:
  print "Live Mode"
elif len(sys.argv) == 2:
  if not os.path.exists(sys.argv[1]):
    print "ERROR: Demo file not accessible"
    exit()
  else:
    demo_file = sys.argv[1]
    print "Demo File = " + demo_file
else:
  print usage
  exit()

#------------------------------------------------
# Main Program Loop
#------------------------------------------------
try:
  InitializeGPIO()
  CheckMotionStarted()
  LEDStatusSolidBlue()

  #------------------------------------------------
  # Initialize Output Window
  #------------------------------------------------
  pygame.init()
  window = pygame.display.set_mode(window_size)
  pygame.display.set_caption(window_title)

  while True:
    #------------------------------------------------
    # Clear Things
    #------------------------------------------------
    LEDCodeOff()
    pygame.draw.rect(window,background_color,full_window_size)

    #------------------------------------------------
    # Add Image to Window
    #------------------------------------------------
    if demo_file != "":
      img_file = demo_file
    else:
      observer = Observer()
      observer.schedule(NewFileEventHandler(), path=image_path)
      observer.start()
      while new_image_file == False:
        time.sleep(cycle_sleep_time)
      observer.stop()
      observer.join()
      new_image_file = False

    img = pygame.image.load(img_file)
    window.blit(img,image_offset)

    #------------------------------------------------
    # Parse QR Code
    #------------------------------------------------
    qr = qrtools.QR()
    qr.decode(img_file)
    if qr.decode():
      qr_code = qr.data_to_string()
      LEDStatusSolidGreen()

      http = urllib3.PoolManager()
      server_response = http.request('GET', qr_code)
      server_html = server_response.data

    else:
      qr_code = "No Code!"
      server_html = ""
      LEDStatusSolidBlue()

    #------------------------------------------------
    # Print QR Code and Server Response in Window
    #------------------------------------------------
    myfont = pygame.font.SysFont(font_type,font_size)
    label = myfont.render(qr_code, 1, font_color)
    window.blit(label, qr_text_offset)

    label = myfont.render(server_html, 1, font_color)
    window.blit(label, server_text_offset)

    #------------------------------------------------
    # Update Window
    #------------------------------------------------
    pygame.display.flip()

    #------------------------------------------------
    # Display Status for Some Time
    #------------------------------------------------
    time.sleep(status_display_time)


#------------------------------------------------
# Cleanup and Exit
#------------------------------------------------
finally:
  pygame.quit()
  GPIO.cleanup()
