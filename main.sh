if [ $(iwgetid -r | grep -c LPU) == 1 ]
then
    echo "Connected to LPU wifi"
else
    echo "Not connected to LPU wifi. Exiting."
    exit 1
fi

username=$1
password=$2

if [ -z "$username" ] || [ -z "$password" ]
then
    echo "Too few arguments. Usage: ./main.sh <username> <password>"
    exit 1
fi

ips=$(hostname -I)
arrIps=(${ips/ / })
ip=${arrIps[0]}

data="mode=191&ipaddress=$ip&username=$username%40lpu.com&password=$password"
res=$(curl -s 'https://10.10.0.1/24online/servlet/E24onlineHTTPClient' --data-raw $data --compressed --insecure)

# These morons are dumb enough to send a 200 OK even if the login fails
# So I have to check the response body
if [[ $res == *"To start surfing"* ]]
then
    echo "Login successful"
else
    echo "Login failed"
fi