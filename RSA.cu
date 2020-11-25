#include <stdio.h>
#include <time.h>
#include <omp.h>
#include "RSA_kernel.cu"
#define BUZZ_SIZE 10002

unsigned long int p, q, n, t, flag, e, d;
unsigned int mm[BUZZ_SIZE], res[BUZZ_SIZE];
void generate_input(int);
void encrypt_cpu(void *ptr,int size);
void decrypt_cpu(void *ptr,int size);
void encrypt_gpu(void *ptr,int size);
void decrypt_gpu(void *ptr,int size);
int threadsPerBlock = 1024;
int blocksPerGrid=64;
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

void encrypt_cpu(void *h_data,int len) {
	double start_encrypt, end_encrypt;
	start_encrypt = clock();
	printf("CPU starts encrypting...\n");
	// unsigned long int  key = e, k;
	unsigned int *mm=(unsigned int *)h_data,*en=mm;
	// printf("\ne=%d\n",key);
	#ifdef _DEBUG
	printf("n%u\n\n\n\n",n);
	#endif

	// len /= sizeof(int);
	#pragma omp parallel for
	for(int i=0;i<len;i++){
		unsigned long key=e,k=1,exp=mm[i]%n;
		while(key){
			if(key%2){
				k*=exp;
				k%=n;
			}
			key/=2;
			exp*=exp;
			exp%=n;
		}
		en[i] = (unsigned int)k;		
		#ifdef _DEBUG
		if(k<0)printf("en_ERROR!!!!!!!!!!!!\n\n\n\n");
		#endif
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
	// FILE *fp = fopen("encrypted_cpu.txt", "wb");
	// if (fp != NULL) {
	// 	for (int k = 0;k<len; k++) {
	// 		fprintf(fp, "%d", en[k]);
	// 	}
	// 	fclose(fp);
	// 	printf("done\n\n");
	// }
}

void encrypt_gpu(void *d_data,int len) {
	cudaEvent_t start_encrypt, stop_encrypt;
	unsigned long int key = e;
	//printf("\nkey=%d, n=%d\n",key,n);
	cudaSetDevice(1);
	unsigned int *dev_num=(unsigned int *)d_data;
	unsigned long *dev_key, *dev_den;
	cudaMalloc((void **) &dev_key, sizeof(long int));
	cudaMalloc((void **) &dev_den, sizeof(long int));
	cudaMemcpy(dev_key, &key, sizeof(long int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_den, &n, sizeof(long int), cudaMemcpyHostToDevice);

	cudaEventCreate(&start_encrypt);
	cudaEventCreate(&stop_encrypt);
	cudaEventRecord(start_encrypt);
	printf("GPU starts encrypting...\n");
	blocksPerGrid=(len+threadsPerBlock-1)/threadsPerBlock;
	rsa<<<blocksPerGrid, threadsPerBlock>>>(dev_num,dev_key,dev_den,len);
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
	// 	for (int i = 0; i < len; i++) {
	// 		fprintf(fp, "%d", res[i] + 96);
	// 	}
	// 	fclose(fp);
	// 	printf("done\n\n");
	// }
}

void decrypt_gpu(void *d_data,int len) {
	cudaEvent_t start_decrypt, stop_decrypt;
	unsigned long int key = d;
	//printf("\nkey=%d, n=%d\n",key,n);
	cudaSetDevice(1);
	unsigned int *dev_num=(unsigned int*)d_data;
	unsigned long *dev_key, *dev_den;
	cudaMalloc((void **) &dev_key, sizeof(long int));
	cudaMalloc((void **) &dev_den, sizeof(long int));
	cudaMemcpy(dev_key, &key, sizeof(long int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_den, &n, sizeof(long int), cudaMemcpyHostToDevice);

	cudaEventCreate(&start_decrypt);
	cudaEventCreate(&stop_decrypt);
	cudaEventRecord(start_decrypt);
	printf("GPU starts decrypting...\n");
	blocksPerGrid=(len+threadsPerBlock-1)/threadsPerBlock;
	rsa<<<blocksPerGrid, threadsPerBlock>>>(dev_num,dev_key,dev_den,len);
	cudaEventRecord(stop_decrypt);
	cudaEventSynchronize(stop_decrypt);
	cudaThreadSynchronize();
	cudaEventElapsedTime(&time_decrypt_gpu, start_decrypt, stop_decrypt);

	cudaFree(dev_key);
	cudaFree(dev_den);
	
	time_decrypt_gpu /= 1000;
	printf("Decryption time taken by GPU: %f s\n", time_decrypt_gpu);
}

void decrypt_cpu(void *h_data,int len) {
	double start_decrypt, end_decrypt;
	unsigned int *mm=(unsigned int *)h_data,*en=mm;
	start_decrypt = clock();
	printf("CPU starts decrypting...\n");
	// unsigned long int  ct, key = d, k;
	// printf("\nd=%d\n",key);
	// len/=sizeof(int);
	#pragma omp parallel for
	for(int i=0;i<len;i++) {
		unsigned long ct = en[i]%n,k = 1,key=d;
		while(key){
			if(key%2==1){
				k*=ct;
				k%=n;
			}
			key/=2;
			ct*=ct;
			ct%=n;
		}
		mm[i] = (unsigned int)k;
		#ifdef _DEBUG
		if(k<0)printf("decrypt_ERROR!!!!!!!!!!!!\n\n\n\n");
		#endif
	}
	end_decrypt = clock();
	time_decrypt_cpu = (double) (end_decrypt - start_decrypt) / CLOCKS_PER_SEC;
	printf("Decryption time taken by CPU: %f s\n", time_decrypt_cpu);
	printf("Saving CPU decrypted file... ");
}
