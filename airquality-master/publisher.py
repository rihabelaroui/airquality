import random
import time
import paho.mqtt.client as mqtt_client
import tkinter as tk
from tkinter import messagebox

# MQTT Broker Details
broker = 'broker.hivemq.com'
port = 1883
topic = "classe/hayder/co2"  

# Generate a random client ID for MQTT
client_id = f'python-mqtt-{random.randint(0, 1000)}'
username = ''
password = ''

# Initial CO2 values and settings
CO2_init = 1000
res = 10
publish_delay = 1
CO2_limit = 6000  # Default limit

# MQTT client
client = None
is_publishing = False  # Track publishing status

def connect_mqtt():
    """Connect to the MQTT broker"""
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
        else:
            print(f"Failed to connect, return code {rc}")
    
    client = mqtt_client.Client(client_id)
    client.username_pw_set(username, password)
    client.on_connect = on_connect
    client.connect(broker, port)
    return client

def publish(client):
    """Publish CO2 values to the MQTT broker"""
    global CO2_init, res, publish_delay, topic, CO2_limit
    CO2 = CO2_init
    while is_publishing:
        time.sleep(publish_delay) 
        
        # Adjust CO2 level based on the resolution
        if CO2 >= 10000:
            CO2 = CO2 - res  
        elif CO2 <= 0:
            CO2 = CO2 + res
        else:
            pas = random.randint(0, 2)
            if pas == 0:
                CO2 = CO2 + res  
            if pas == 2:
                CO2 = CO2 + res  

        msg = f'{CO2}'

        # Check if CO2 exceeds the limit and show alert
        if CO2 >= CO2_limit:
            show_alert(f"CO2 level has reached {CO2} ppm, exceeding the limit!")

        client.publish(topic, msg)
        print(f"Send `{msg}`ppm to topic `{topic}`")

def show_alert(message):
    """Display an alert message in the GUI"""
    alert_text.set(message)  # Update alert message on the GUI
    print(message)

def toggle_publishing():
    """Toggle between starting and stopping the publishing process"""
    global is_publishing
    if not is_publishing:
        # Start publishing
        try:
            CO2_init = int(co2_init_entry.get())
            res = int(res_entry.get())
            publish_delay = float(delay_entry.get())  # Set delay from user input
            topic = topic_entry.get()  # Set topic from user input
            CO2_limit = int(limit_entry.get())  # Get CO2 limit from user input
            
            if CO2_init < 0 or res <= 0 or publish_delay <= 0 or CO2_limit <= 0:
                raise ValueError
            
        except ValueError:
            print("Please enter valid values for CO2_init, res, delay, and limit (positive numbers).")
            return
        
        client = connect_mqtt()
        client.loop_start()
        is_publishing = True
        toggle_button.config(text="Stop Publishing", bg="#FF6347", activebackground="#FF4500")
        publish(client)
    else:
        # Stop publishing
        is_publishing = False
        toggle_button.config(text="Start Publishing", bg="#32CD32", activebackground="#228B22")

# Create Tkinter window
root = tk.Tk()
root.title("CO2 Monitor")
root.geometry("450x500")  # Define window size
root.config(bg="#f4f4f9")  # Set background color

# Create main frame for organizing content
main_frame = tk.Frame(root, bg="#f4f4f9")
main_frame.pack(pady=20)

# Create and place labels and entry widgets for variables
tk.Label(main_frame, text="MQTT Topic:", font=("Arial", 12), bg="#f4f4f9").grid(row=0, column=0, padx=10, pady=10, sticky="w")
topic_entry = tk.Entry(main_frame, font=("Arial", 12))
topic_entry.grid(row=0, column=1, padx=10, pady=10)
topic_entry.insert(0, topic) 

tk.Label(main_frame, text="Initial CO2 Level:", font=("Arial", 12), bg="#f4f4f9").grid(row=1, column=0, padx=10, pady=10, sticky="w")
co2_init_entry = tk.Entry(main_frame, font=("Arial", 12))
co2_init_entry.grid(row=1, column=1, padx=10, pady=10)
co2_init_entry.insert(0, str(CO2_init))  

tk.Label(main_frame, text="CO2 Change Resolution:", font=("Arial", 12), bg="#f4f4f9").grid(row=2, column=0, padx=10, pady=10, sticky="w")
res_entry = tk.Entry(main_frame, font=("Arial", 12))
res_entry.grid(row=2, column=1, padx=10, pady=10)
res_entry.insert(0, str(res))  

tk.Label(main_frame, text="Publishing Delay (seconds):", font=("Arial", 12), bg="#f4f4f9").grid(row=3, column=0, padx=10, pady=10, sticky="w")
delay_entry = tk.Entry(main_frame, font=("Arial", 12))
delay_entry.grid(row=3, column=1, padx=10, pady=10)
delay_entry.insert(0, str(publish_delay))  

# Add CO2 Limit input
tk.Label(main_frame, text="CO2 Limit (ppm):", font=("Arial", 12), bg="#f4f4f9").grid(row=4, column=0, padx=10, pady=10, sticky="w")
limit_entry = tk.Entry(main_frame, font=("Arial", 12))
limit_entry.grid(row=4, column=1, padx=10, pady=10)
limit_entry.insert(0, str(CO2_limit))  

# Start/Stop button
toggle_button = tk.Button(main_frame, text="Start Publishing", command=toggle_publishing, bg="#32CD32", font=("Arial", 14), width=20, height=2, relief="raised", bd=5)
toggle_button.grid(row=5, column=0, columnspan=2, pady=20)

# Alert Label
alert_text = tk.StringVar()
alert_label = tk.Label(root, textvariable=alert_text, fg="red", font=("Arial", 14, "bold"), wraplength=350, bg="#f4f4f9")
alert_label.pack(pady=10)

root.mainloop()
