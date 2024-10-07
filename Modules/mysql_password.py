from cryptography.fernet import Fernet

# To generate a key and save it to a file
key = Fernet.generate_key()
with open('key.key', 'wb') as key_file:
    key_file.write(key)

# Load the key
with open('key.key', 'rb') as key_file:
    key = key_file.read()

cipher = Fernet(key)

# Encrypt the password
encrypted_password = cipher.encrypt(b"Nu66et")
with open('password.enc', 'wb') as enc_file:
    enc_file.write(encrypted_password)

# Decrypt the password
with open('password.enc', 'rb') as enc_file:
    encrypted_password = enc_file.read()
    password = cipher.decrypt(encrypted_password).decode('utf-8')

print(password)
