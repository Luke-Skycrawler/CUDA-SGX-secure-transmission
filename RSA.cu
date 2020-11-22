#include <stdio.h>
#include <time.h>
#include "RSA_kernel.cu"
#define BUZZ_SIZE 10002

int p, q, n, t, flag, e[100], d[100], mm[BUZZ_SIZE], res[BUZZ_SIZE];
char msg[BUZZ_SIZE];
int prime(long int);
void generate_input(int);
void ce();
long int cd(long int);
void encrypt_cpu(void *ptr,int size);
void decrypt_cpu(void *ptr,int size);
void encrypt_gpu(void *ptr,int size);
void decrypt_gpu(void *ptr,int size);
int threadsPerBlock = 1024;
int blocksPerGrid;
time_t tt;
double time_encrypt_cpu, time_decrypt_cpu;
float time_encrypt_gpu = 0.0;
float time_decrypt_gpu = 0.0;
int prime(long int pr) {
	int j = sqrt(pr);
	for (int i = 2; i <= j; i++) {
		if (pr % i == 0)
			return 0;
	}
	return 1;
}

void ce() {
	int k;
	k = 0;
	for (int i = 2; i < t; i++) {
		if (t % i == 0)
			continue;
		flag = prime(i);
		if (flag == 1 && i != p && i != q) {
			e[k] = i;
			flag = cd(e[k]);
			if (flag > 0) {
				d[k] = flag;
				k++;
			}
			if (k == 99)
				break;
		}
	}
}

long int cd(long int x) {
	long int k = 1;
	while (1) {
		k = k + t;
		if (k % x == 0)
			return (k / x);
	}
}

void encrypt_cpu(void *h_data,int len) {
	double start_encrypt, end_encrypt;
	start_encrypt = clock();
	printf("CPU starts encrypting...\n");
	int pt, key = e[0], k;
	int *mm=(int *)h_data,*en=mm;
	printf("\ne=%d\n",key);
	// len /= sizeof(int);
	for(int i=0;i<len;i++){
		pt = mm[i];
		k = 1;
		for (int j = 0; j < key; j++) {
			k = k * pt;
			k = k % n;
		}
		en[i] = k;

	}
	end_encrypt = clock();
	time_encrypt_cpu = (double) (end_encrypt - start_encrypt) / CLOCKS_PER_SEC;
	printf("Encryption time taken by CPU: %f s\n", time_encrypt_cpu);
	/*
	 en[i] = -1;
	 printf("\nCPU ENCRYPTED MESSAGE IS\n");
	 for (i = 0; en[i] != -1; i++)
	 printf("%d ", en[i]);
	 */

	printf("Saving CPU encrypted file... ");
	// en[i] = -1;
	FILE *fp = fopen("encrypted_cpu.txt", "wb");
	if (fp != NULL) {
		for (int k = 0;k<len; k++) {
			fprintf(fp, "%d", en[k]);
		}
		fclose(fp);
		printf("done\n\n");
	}
}

void encrypt_gpu(void *d_data,int len) {
	cudaEvent_t start_encrypt, stop_encrypt;
	int key = e[0];
	//printf("\nkey=%d, n=%d\n",key,n);
	cudaSetDevice(1);
	int *dev_num=(int *)d_data, *dev_key, *dev_den;
	cudaMalloc((void **) &dev_key, sizeof(int));
	cudaMalloc((void **) &dev_den, sizeof(int));
	cudaMemcpy(dev_key, &key, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_den, &n, sizeof(int), cudaMemcpyHostToDevice);

	cudaEventCreate(&start_encrypt);
	cudaEventCreate(&stop_encrypt);
	cudaEventRecord(start_encrypt);
	printf("GPU starts encrypting...\n");
	rsa<<<blocksPerGrid, threadsPerBlock>>>(dev_num,dev_key,dev_den);
	cudaEventRecord(stop_encrypt);
	cudaEventSynchronize(stop_encrypt);
	cudaThreadSynchronize();
	cudaEventElapsedTime(&time_encrypt_gpu, start_encrypt, stop_encrypt);

	// cudaMemcpy(res, dev_num, len * sizeof(int), cudaMemcpyDeviceToHost);
	// cudaFree(dev_num);
	cudaFree(dev_key);
	cudaFree(dev_den);
	time_encrypt_gpu /= 1000;
	printf("Encryption time taken by GPU: %f s\n", time_encrypt_gpu);

	/*
	 printf("\nGPU ENCRYPTED MESSAGE IS\n");
	 for (i = 0; i < len; i++)
	 printf("%d ", res[i]+96);
	 printf("\n");
	 */

	printf("Saving GPU encrypted file... ");
	// FILE *fp = fopen("encrypted_gpu.txt", "wb");
	// if (fp != NULL) {
	// 	for (i = 0; i < len; i++) {
	// 		fprintf(fp, "%d", res[i] + 96);
	// 	}
	// 	fclose(fp);
	// 	printf("done\n\n");
	// }
}

void decrypt_gpu(void *d_data,int len) {
	cudaEvent_t start_decrypt, stop_decrypt;
	int key = d[0];
	//printf("\nkey=%d, n=%d\n",key,n);
	cudaSetDevice(1);
	int *dev_num=(int*)d_data, *dev_key, *dev_den;
	cudaMalloc((void **) &dev_key, sizeof(int));
	cudaMalloc((void **) &dev_den, sizeof(int));
	cudaMemcpy(dev_key, &key, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_den, &n, sizeof(int), cudaMemcpyHostToDevice);

	cudaEventCreate(&start_decrypt);
	cudaEventCreate(&stop_decrypt);
	cudaEventRecord(start_decrypt);
	printf("GPU starts decrypting...\n");
	rsa<<<blocksPerGrid, threadsPerBlock>>>(dev_num,dev_key,dev_den);
	cudaEventRecord(stop_decrypt);
	cudaEventSynchronize(stop_decrypt);
	cudaThreadSynchronize();
	cudaEventElapsedTime(&time_decrypt_gpu, start_decrypt, stop_decrypt);

	cudaFree(dev_key);
	cudaFree(dev_den);
	
	time_decrypt_gpu /= 1000;
	printf("Decryption time taken by GPU: %f s\n", time_decrypt_gpu);
	
	/*
	printf("\nGPU DECRYPTED MESSAGE IS\n");
	for (i = 0; i < len; i++)
	printf("%d ", res[i]+96);
	printf("\n");
	*/
	
}

void decrypt_cpu(void *h_data,int len) {
	double start_decrypt, end_decrypt;
	int *mm=(int *)h_data,*en=mm;
	start_decrypt = clock();
	printf("CPU starts decrypting...\n");
	long int key = d[0], k;
	printf("\nd=%d\n",key);
	// len/=sizeof(int);
	// #pragma omp parallel for
	for(int i=0;i<len;i++){
		int ct = en[i];
		k = 1;
		for (int j = 0; j < key; j++) {
			k = k * ct;
			k = k % n;
		}
		mm[i] = k;
		i++;
	}
	while (i<len) {
	}
	end_decrypt = clock();
	time_decrypt_cpu = (double) (end_decrypt - start_decrypt) / CLOCKS_PER_SEC;
	printf("Decryption time taken by CPU: %f s\n", time_decrypt_cpu);

	/*
	 m[i] = -1;
	 printf("\nCPU DECRYPTED MESSAGE IS\n");
	 for (i = 0; m[i] != -1; i++)
	 printf("%d ", m[i]);
	 printf("\n");
	 */

	printf("Saving CPU decrypted file... ");
	// FILE *fp = fopen("decrypted_cpu.txt", "wb");
	// if (fp != NULL) {
	// 	for (int k = 0; k<len; k++) {
	// 		fprintf(fp, "%c", mm[k]+96);
	// 	}
	// 	fprintf(fp, "\n");
	// 	fclose(fp);
	// 	printf("done\n\n");
	// }
}
