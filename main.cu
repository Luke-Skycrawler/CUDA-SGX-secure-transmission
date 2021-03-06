#include "RSA.cu"
int numChars;
int main() {

	p = 157;
	q = 373;

	srand((unsigned) time(&tt));/* Intializes random number generator */
	generate_input(10000);

	FILE *f = fopen("input.txt", "r");
	if (f == NULL) {
		perror("Error opening file");
		return (1);
	}
	if (fgets(msg, BUZZ_SIZE, f) != NULL) {
		//printf("String read: %s\n", msg);
		printf("Reading input file...done(");
	}
	fclose(f);

	numChars = strlen(msg) - 1;
	msg[numChars] = '\0';
	printf("numChars: %d)\n\n", numChars);
	blocksPerGrid = (numChars + threadsPerBlock - 1) / threadsPerBlock;

	/*
	 printf("\nENTER MESSAGE\n");
	 fflush(stdin);
	 scanf("%s", msg);
	 numChars = strlen(msg);
	 blocksPerGrid =(numChars + threadsPerBlock - 1) / threadsPerBlock;
	 */

	for (int i = 0; msg[i] != '\0'; i++)
		mm[i] = msg[i] - 96;
	n = p * q;
	t = (p - 1) * (q - 1);
	ce();
	/*
	 printf("\nPOSSIBLE VALUES OF e AND d ARE\n");
	 for (i = 0; i < j - 1; i++)
	 printf("\n%ld\t%ld", e[i], d[i]);
	 */

	encrypt_cpu(mm,numChars);
	decrypt_cpu(mm,numChars);
	FILE *fpc = fopen("decrypted_cpu.txt", "wb");
	if (fpc != NULL) {
		for (int i = 0; i < numChars; i++) {
			fprintf(fpc, "%c", mm[i] + 96);
		}
		fprintf(fpc, "\n");
		fclose(fpc);
		printf("done\n\n");
	}
	int * dev_num;
	cudaMalloc((void **) &dev_num, numChars * sizeof(int));
	cudaMemcpy(dev_num, mm, numChars * sizeof(int), cudaMemcpyHostToDevice);
	encrypt_gpu(dev_num,numChars);
	decrypt_gpu(dev_num,numChars);
	printf("GPU encryption speed up: %f\n",
			time_encrypt_cpu / time_encrypt_gpu);
	printf("GPU decryption speed up: %f\n\n",
			time_decrypt_cpu / time_decrypt_gpu);
	cudaMemcpy(res, dev_num, numChars * sizeof(int), cudaMemcpyDeviceToHost);
	printf("Saving GPU decrypted file... ");
	FILE *fp = fopen("decrypted_gpu.txt", "wb");
	if (fp != NULL) {
		for (int i = 0; i < numChars; i++) {
			fprintf(fp, "%c", res[i] + 96);
		}
		fprintf(fp, "\n");
		fclose(fp);
		printf("done\n\n");
	}
	cudaFree(dev_num);
	return 0;
}

void generate_input(int size) {
	printf("\nGenerating input file... ");
	FILE *fp = fopen("input.txt", "wb");
	if (fp != NULL) {
		for (int k = 0; k < size; k++) {
			int r = rand() % 26;
			fprintf(fp, "%c", r + 97);
		}
		fprintf(fp, "\n");
		fclose(fp);
		printf("done\n");
	}
}

