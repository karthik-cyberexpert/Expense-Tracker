import firebase_admin
from firebase_admin import credentials, messaging
import sys
import json

def send_notification(token, source="Manual"):
    try:
        # Load the service account file from current directory
        cred = credentials.Certificate('expense-tracker-83492-firebase-adminsdk-fbsvc-fe87ee23f1.json')
        
        # Initialize the app if not already initialized
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)

        message = messaging.Message(
            notification=messaging.Notification(
                title='Payment Detected',
                body=f'Did you just pay using {source}?',
            ),
            data={
                'route': '/add_transaction',
                'source': source,
            },
            token=token,
        )

        response = messaging.send(message)
        print(f'Successfully sent message: {response}')
        return True
    except Exception as e:
        print(f'Error sending message: {e}')
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python trigger_notification.py <DEVICE_FCM_TOKEN> [SOURCE_APP_NAME]")
        sys.exit(1)
    
    token = sys.argv[1]
    source = sys.argv[2] if len(sys.argv) > 2 else "Firebase"
    send_notification(token, source)
