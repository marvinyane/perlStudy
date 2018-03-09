#include <stdio.h>
#include <time.h>

typedef struct
{
    int type;
    int pid;
    char line[32];
    int inittab;
    char user[32];
    char host[256];
    int t1;
    int t2;
    int t3;
    int t4;
    int t5;
    char tmp[32];
}RECORD_T;

const char *my_time = "Wed Dec  3 18:30:24";

int main()
{
    FILE* fp = fopen("wtmp", "r");
    FILE* new_fp = fopen("new", "wb");

    if (fp == NULL || new_fp == NULL)
    {
        perror("file open failed:");
        return 0;
    }
        
    RECORD_T record;
    memset(&record, 0, sizeof(RECORD_T));

    while(!feof(fp))
    {
        fread(&record, sizeof(RECORD_T), 1, fp);
        printf("%s - %s - %s \n", record.user, record.line, record.host);
        struct tm* timeinfo;
        timeinfo = localtime(&record.t3);
        char* cur_time = asctime(timeinfo);

        if (strncmp(cur_time, my_time, strlen(my_time)) == 0)
        {
            record.t3 += 1750;
        }

        fwrite(&record, sizeof(RECORD_T), 1, new_fp);

        memset(&record, 0, sizeof(RECORD_T));
    }

    close(fp);
    close(new_fp);
    return 0;
}
