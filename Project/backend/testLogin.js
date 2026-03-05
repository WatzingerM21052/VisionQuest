const http = require('http');

const postData = JSON.stringify({
    username: 'admin',
    password: 'htlgkr'
});

const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': postData.length
    }
};

const req = http.request(options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        console.log('\n=== LOGIN RESPONSE ===\n');
        console.log('Status Code:', res.statusCode);
        console.log('\nResponse Body:');
        try {
            const parsed = JSON.parse(data);
            console.log(JSON.stringify(parsed, null, 2));

            if (parsed.data && parsed.data.user) {
                console.log('\n=== USER OBJECT ===');
                console.log('Role:', parsed.data.user.role);
                console.log('Role (uppercase check):', parsed.data.user.ROLE);
            }
        } catch (e) {
            console.log(data);
        }
    });
});

req.on('error', (e) => {
    console.error('Error:', e.message);
});

req.write(postData);
req.end();
