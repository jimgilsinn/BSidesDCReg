#!/usr/bin/python
#################################################
#
# BSidesDC QR Code Reader Registration System
# Using a Raspberry Pi
#
# Version
# -------------------------------
# 1.0	jdg	Initial Version
#
# Authors
# -------------------------------
# jdg	Jim Gilsinn
#
#################################################

import sys, os, time

usage = "\nUsage:\tqr-reg.py [demo_file]\n\n"
usage += "Process QR codes generated by the BSidesDC\n"
usage += "registration system.\n\n"
usage += "demo_file\t(optional) Process and display\n"
usage += "\t\tthe desired demonstration file\n"

#------------------------------------------------
# Check for a demo test file
#------------------------------------------------
demo_file = ""
if len(sys.argv) == 1:
  print "Live Mode"
elif len(sys.argv) == 2:
#  print "Demo Mode"
  if not os.path.exists(sys.argv[1]):
    print "ERROR: Demo file not accessible"
    exit()
  else:
    demo_file = sys.argv[1]
    print "Demo File = " + demo_file
else:
  print usage
  exit()

import pygame, qrtools
import RPi.GPIO as GPIO

#------------------------------------------------
# Initialize Output Window
#------------------------------------------------
pygame.init()
window_size = (640,480)
image_size = (640,360)
window_title = "BSidesDC Registration"
window = pygame.display.set_mode(window_size)
pygame.display.set_caption(window_title)

#------------------------------------------------
# Add Image to Window
#------------------------------------------------
if demo_file != "":
  img_file = demo_file
else:
# Kludge to test right now with the demo file
  img_file = demo_file

img = pygame.image.load(img_file)
img = pygame.transform.scale(img,image_size)
window.blit(img,(0,120))

#------------------------------------------------
# Parse QR Code
#------------------------------------------------
qr = qrtools.QR()
qr.decode(img_file)
if qr.decode():
  qr_code = qr.data_to_string()
else:
  qr_code = "Invalid!"

#------------------------------------------------
# Print QR Code in Window
#------------------------------------------------
font_color = (255,255,0)
myfont = pygame.font.SysFont("monospace",15)
label = myfont.render(qr_code, 1, font_color)
window.blit(label,(50,25))

#------------------------------------------------
# Update Window
#------------------------------------------------
pygame.display.flip()

#------------------------------------------------
# Cleanup and Exit
#------------------------------------------------
time.sleep(10)
pygame.quit()
#GPIO.cleanup()
