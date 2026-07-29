import sys, base64
# Base64-encoded GDScript content
data = sys.argv[1]
with open('scripts/ui/DPSMeter.gd', 'w', encoding='utf-8') as f:
    f.write(data)
print('Written: {} chars'.format(len(data)))
