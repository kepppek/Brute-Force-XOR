#include <cuda_runtime.h>
#include <stdio.h>
#include <time.h>
#include "device_launch_parameters.h"
#include <conio.h>
#include <string>

using namespace std;

const int lengthText = 11;      // длина текста
const int lengthAlphabet = 27;  // мощность алфавита
const int lengthCombinations = 5;            // количество перебираемых комбинаций
const int lengthKey = 5;           // длина настоящего ключа

const int P = 24576;  // количество потоков

//Функция сложения
__global__ void calculate(unsigned int* hashSource, int* finishThread, unsigned char* intClosed, unsigned char* intRange, unsigned char* alphabet)
{
    int id = blockIdx.x * blockDim.x + threadIdx.x;

    if (id >= *finishThread)
        return;
    
    unsigned char start[lengthCombinations];
    unsigned char finish[lengthCombinations];

    unsigned char i = 0;

    for (i = 0; i < lengthCombinations; i++)
        start[i] = intRange[id * lengthCombinations + i];

    id = id + 1;

    if (id == P)
        id = id - 1;

    for (i = 0; i < lengthCombinations; i++)
        finish[i] = intRange[id * lengthCombinations + i];


    unsigned int hash = 0;
    unsigned int hashS = *hashSource;
    unsigned char count = 0;
    unsigned char line[lengthCombinations + 1];
    line[lengthCombinations] = '\0';

    while (true)
    {
         //вывод варианта множества на экран
        for (i = 0; i < lengthText; i++)
        {
            // считаем хеш и дешифруем текст
            hash = (hash * 1664525) + ((intClosed[i] - start[i % lengthCombinations] + lengthAlphabet) % lengthAlphabet) + 1013904223;
        }

        // проверка на совпадение хеша
        if (hash == hashS)
        {
             // выводим
            for (i = 0; i < lengthCombinations; i++)
                line[i] = alphabet[start[i]];

            printf("%s = %u = %d \n", line, hash, id);
        }

        hash = 0;

        for (i = 0; i < lengthCombinations; i++)
        {
            // считаем количество совпадений
            if (start[i] == finish[i])
                count++;
            else
                break;
        }


        // условие завершения потока
        if (count == lengthCombinations)
            break;
        else
            count = 0;


        for (i = lengthCombinations - 1; i > -1; i--)
        {
            if (start[i] + 1 == lengthAlphabet)
            {
                start[i] = 0;
            }
            else
            {
                start[i]++;
                break;
            }
        }
    }
}



int main(int argc, char* argv[])
{
    string textSource = "hello world";		  // незашифрованный текст
    string key = "hello";						  // ключ

    unsigned int hash = 0;				      // хеш
    unsigned char intRange[P * lengthCombinations];// границы вычислений для каждого потока
    unsigned char intSource[lengthText];	  // кодированный исходный текст
    unsigned char intOpen[lengthText];		  // кодированный расшифрованный текст
    unsigned char intKey[lengthKey];		  // кодированный ключ
    unsigned char intClosed[lengthText];	  // кодированный зашифрованный текст
    unsigned char alphabet[lengthAlphabet] =  // алфавит
    { 'a', 'b', 'c', 'd' ,'e' ,'f' ,
      'g', 'h' ,'i' ,'j' ,'k' ,'l' ,
      'm' ,'n' ,'o' ,'p' ,'q' ,'r' ,
      's' ,'t' ,'u' ,'v' ,'w' ,'x' ,
      'y' ,'z',' ' };

    // кодируем исходный текст
    for (int i = 0; i < lengthText; i++)
    {
        for (int j = 0; j < lengthAlphabet; j++)
        {
            if (textSource[i] == alphabet[j])
            {
                intSource[i] = (unsigned char)j;
                break;
            }
        }
    }

    // кодируем ключ
    for (int i = 0; i < lengthKey; i++)
    {
        for (int j = 0; j < lengthAlphabet; j++)
        {
            if (key[i] == alphabet[j])
            {
                intKey[i] = (unsigned char)j;
                break;
            }
        }
    }

    //вычисляем хеш 
    for (int i = 0; i < lengthText; i++)
    {
        hash = (hash * 1664525) + intSource[i] + 1013904223;
    }

    // шифруем текст
    for (int i = 0; i < lengthText; i++)
    {
        intClosed[i] = (intSource[i] + intKey[i % lengthKey]) % lengthAlphabet;
    }

    // дешифруем текст
    for (int i = 0; i < lengthText; i++)
    {
        intOpen[i] = (intClosed[i] - intKey[i % lengthKey] + lengthAlphabet) % lengthAlphabet;
    }

    // Определяем границы вычислений для каждого потока
    unsigned long long countCombinations = pow(lengthAlphabet, lengthCombinations);
    unsigned long long rangeCombinations = countCombinations / P + 1; // количество комбинаций на один поток
    unsigned long long number = 0; // номер комбинации с которой начинаем
    int finishThread = 0; // 

    printf("Text = %s\n", textSource);
    printf("Hash of the text = %u\n", hash);
    printf("Key = %s\n", key);
    printf("Number of combinations = %llu\n", countCombinations);
    printf("Number of combinations per thread = %llu\n", rangeCombinations);
    printf("\n===Start calculation===\n\n");


    for (int i = 0; i < P; i++)
    {
        number = i * rangeCombinations;

        if (number >= countCombinations || i == P - 1)
        {
            finishThread = i;

            for (int j = 0; j < lengthCombinations; j++)
                intRange[i * lengthCombinations + (lengthCombinations - j - 1)] = lengthAlphabet - 1;
            
            break;
        }

        for (int j = 0; j < lengthCombinations; j++)
        {
            intRange[i * lengthCombinations + (lengthCombinations - j - 1)] = number % lengthAlphabet;
            number = number / lengthAlphabet;
        }
    }

    unsigned int* Hash;
    int* FinishThread;
    unsigned char* IntClosed;
    unsigned char* IntRange;
    unsigned char* Alphabet;


    clock_t t;
    t = clock();

      //Выделение памяти на устройстве
    cudaMalloc((void**)&Hash, sizeof(unsigned int));
    cudaMalloc((void**)&FinishThread, sizeof(int));
    cudaMalloc((void**)&IntClosed, sizeof(unsigned char) * lengthText);
    cudaMalloc((void**)&IntRange, sizeof(unsigned char) * lengthCombinations * P);
    cudaMalloc((void**)&Alphabet, sizeof(unsigned char) * lengthAlphabet);

     //Копируем данные на устройство
    cudaMemcpy(Hash, &hash, sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(FinishThread, &finishThread, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(IntClosed, intClosed, lengthText * sizeof(unsigned char), cudaMemcpyHostToDevice);
    cudaMemcpy(IntRange, intRange, lengthCombinations * P * sizeof(unsigned char), cudaMemcpyHostToDevice);
    cudaMemcpy(Alphabet, alphabet, lengthAlphabet * sizeof(unsigned char), cudaMemcpyHostToDevice);

    calculate << <96, 256 >> > (Hash, FinishThread, IntClosed, IntRange, Alphabet);

    //Хост ожидает завершения работы девайса
    //cudaDeviceSynchronize();

    //Получаем результат
   // cudaMemcpy(&b, dev_b, sizeof(int), cudaMemcpyHostToHost);

    //Очищаем память на устройстве
    cudaFree(Hash);
    cudaFree(FinishThread);
    cudaFree(IntClosed);
    cudaFree(IntRange);
    cudaFree(Alphabet);

    t = clock() - t;
    printf("\ntime %.3f\n", ((double)t) / CLOCKS_PER_SEC);


    getch();
    return 0;
}
