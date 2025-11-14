# Git Bash Commands for Password Generation

## Quick Commands (Copy & Paste)

Open **Git Bash** and run these commands:

```bash
# Navigate to the jitsi directory
cd /c/Users/ASUS/OneDrive/Desktop/collabesphere/docker/jitsi

# Make the script executable
chmod +x generate-passwords.sh

# Run the script
./generate-passwords.sh
```

That's it! The script will:
1. Generate 4 random passwords
2. Automatically update your `.env` file (if it exists)
3. Or display the passwords for you to copy manually

---

## If .env file doesn't exist yet:

1. First create the `.env` file (copy from SETUP.md or create manually)
2. Then run the script again

---

## Verify it worked:

After running, check your `.env` file - you should see:
```
JVB_AUTH_PASSWORD=<some-random-hex-string>
JICOFO_AUTH_PASSWORD=<some-random-hex-string>
JIBRI_RECORDER_PASSWORD=<some-random-hex-string>
JIBRI_XMPP_PASSWORD=<some-random-hex-string>
```

---

## All-in-One Command (if you're already in the directory):

```bash
chmod +x generate-passwords.sh && ./generate-passwords.sh
```

