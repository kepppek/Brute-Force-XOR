#include <iostream>
#include <time.h>

const int lengthText = 11;      // длина текста
const int lengthAlphabet = 27;  // мощность алфавита
const int lengthCombinations = 7;            // количество перебираемых комбинаций
const int lengthKey = 7;           // длина настоящего ключа

using namespace std;

void calculate(unsigned int* hashSource, unsigned char* intClosed, unsigned char* alphabet)
{
    unsigned char start[lengthCombinations];
    unsigned char finish[lengthCombinations];

    unsigned char i = 0;

    for (i = 0; i < lengthCombinations; i++)
        start[i] = 0;

    for (i = 0; i < lengthCombinations; i++)
        finish[i] = lengthAlphabet -1;


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

            printf("%s = %u \n", line, hash);
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


int main()
{
    string textSource = "hello world";		  // незашифрованный текст
    string key = "helllll";						  // ключ

    unsigned int hash = 0;				      // хеш
   // unsigned char intRange[P * lengthCombinations];// границы вычислений для каждого потока
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

    unsigned long long countCombinations = pow(lengthAlphabet, lengthCombinations);

    printf("Text = %s\n", textSource);
    printf("Hash of the text = %u\n", hash);
    printf("Key = %s\n", key);
    printf("Number of combinations = %llu\n", countCombinations);
    printf("\n===Start calculation===\n\n");

    clock_t t;
    t = clock();

    calculate(&hash,intClosed,alphabet);

    t = clock() - t;
    printf("\ntime %.3f\n", ((double)t) / CLOCKS_PER_SEC);


    return 0;
}

