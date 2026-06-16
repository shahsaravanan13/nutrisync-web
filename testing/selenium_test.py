import os
import sys
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def run_test():
    print("Starting Selenium web smoke test...")
    
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--window-size=1280,800")
    
    try:
        driver = webdriver.Chrome(options=chrome_options)
        url = "http://localhost:3000"
        print(f"Navigating to web app URL: {url}")
        driver.get(url)
        
        # Wait for the document to load and check the page title
        WebDriverWait(driver, 15).until(
            lambda d: d.execute_script("return document.readyState") == "complete"
        )
        
        time.sleep(3) # Wait for Flutter to initialize
        
        title = driver.title
        print(f"Page title is: '{title}'")
        
        # Verify the title contains project keywords (nutrisyncproject or nutrisync)
        if "nutrisync" in title.lower():
            print("Selenium Test Status: PASS")
            write_result("PASS", f"Web app loaded successfully. Page title: '{title}'")
            driver.quit()
            sys.exit(0)
        else:
            raise Exception(f"Unexpected page title: '{title}'")
            
    except Exception as e:
        print(f"Selenium Test Status: FAIL. Error: {str(e)}")
        write_result("FAIL", f"Failed to load website or verify content: {str(e)}")
        sys.exit(1)

def write_result(status, message):
    os.makedirs("testing", exist_ok=True)
    with open("testing/selenium_result.txt", "w") as f:
        f.write(f"STATUS={status}\n")
        f.write(f"MESSAGE={message}\n")

if __name__ == "__main__":
    run_test()
