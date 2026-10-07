import http from 'k6/http';
import { sleep, check } from 'k6';

// This is a basic k6 load test script.
// You can run it with: k6 run test/load_test.js

export const options = {
  // A simple test with 10 concurrent virtual users for 30 seconds
  stages: [
    { duration: '10s', target: 10 }, // Ramp up to 10 users over 10s
    { duration: '10s', target: 10 }, // Stay at 10 users for 10s
    { duration: '10s', target: 0 },  // Ramp down to 0 users over 10s
  ],
  thresholds: {
    // 95% of requests must complete below 500ms
    http_req_duration: ['p(95)<500'],
  },
};

// To do a REAL load test, place a real image named 'test_image.jpg' in the test folder.
// Note: In k6, reading files using open() must be done in the global "init" scope, outside the default function.
let imgData = null;
try {
  imgData = open('./test_image.jpg', 'b');
} catch (e) {
  // If the file doesn't exist, we will use a dummy string just to prevent a crash
  imgData = 'dummy_image_data_that_is_not_a_real_image';
}

export default function () {
  // Replace with the actual API endpoint you want to load test.
  // We found this base URL in your app's codebase.
  const BASE_URL = 'https://pasteshub404-navikarana-backend.hf.space';

  // We hit a 404 on the root endpoint. 
  // Let's test the actual face verification endpoint we found in your code: /login-face
  const faceVerifyUrl = `${BASE_URL}/login-face`;

  // Note: For multipart/form-data, you'd usually need to read an image file first.
  // We'll send a dummy payload here just to hit the endpoint. 
  // If your backend expects a real image, it might return a 400 or 422 error, 
  // but at least it won't be a 404 Not Found!
  
  // The backend requires both 'image' and 'username' fields in the form data.
  const payload = { 
    username: 'testuser',
    image: imgData === 'dummy_image_data_that_is_not_a_real_image' 
           ? imgData 
           : http.file(imgData, 'test_image.jpg')
  };

  const res = http.post(faceVerifyUrl, payload);

  const isSuccess = check(res, {
    'status is 200': (r) => r.status === 200,
  });

  if (!isSuccess) {
    console.log(`Failed! Status: ${res.status}, Body: ${res.body.substring(0, 100)}...`);
  }

  sleep(1);
}
