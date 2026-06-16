import os
import sys
import glob
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options

def run_test():
    print("Starting Appium smoke test...")
    
    # Locate the built APK
    apk_dir = "frontend_temp/build/app/outputs/flutter-apk"
    apk_pattern = os.path.join(apk_dir, "*release.apk")
    apks = glob.glob(apk_pattern)
    
    if not apks:
        print("Error: No APK found to test.")
        write_result("FAIL", "No APK found in build directory.")
        sys.exit(1)
        
    # Prefer x86_64 apk for the emulator if available
    apk_path = apks[0]
    for apk in apks:
        if "x86_64" in apk:
            apk_path = apk
            break
            
    print(f"Testing APK: {apk_path}")
    
    options = UiAutomator2Options()
    options.platform_name = "Android"
    options.device_name = "Android Emulator"
    options.automation_name = "UiAutomator2"
    options.app = os.path.abspath(apk_path)
    options.set_capability("autoGrantPermissions", True)
    options.set_capability("newCommandTimeout", 60)
    
    try:
        # Connect to Appium Server
        # Appium 2.x uses '/' as base path by default
        driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
        print("Connected to Appium server successfully.")
        
        # Wait for app to launch
        time.sleep(10)
        
        # Basic check to verify the app package is running
        current_package = driver.current_package
        print(f"Active application package: {current_package}")
        
        if "nutrisyncproject" in current_package or "example" in current_package:
            print("Appium Test Status: PASS")
            write_result("PASS", f"App launched successfully. Active package: {current_package}")
            driver.quit()
            sys.exit(0)
        else:
            raise Exception(f"Unexpected package name running: {current_package}")
            
    except Exception as e:
        print(f"Appium Test Status: FAIL. Error: {str(e)}")
        write_result("FAIL", f"Failed during UI automation: {str(e)}")
        sys.exit(1)

def write_result(status, message):
    os.makedirs("testing", exist_ok=True)
    with open("testing/appium_result.txt", "w") as f:
        f.write(f"STATUS={status}\n")
        f.write(f"MESSAGE={message}\n")

if __name__ == "__main__":
    run_test()
