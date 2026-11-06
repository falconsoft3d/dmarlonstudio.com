#include <stdio.h>
#define SUBJECTS 3  // a name for a fixed value, replaced before compiling
typedef enum { FAIL, PASS, MERIT } Result;
typedef struct { char name[16]; double marks[SUBJECTS]; } Student;

double average(const Student *s) {
    double sum = 0;
    for (int i = 0; i < SUBJECTS; i++) sum += s->marks[i];
    return sum / SUBJECTS;
}

Result result_of(double avg) {
    return avg >= 8.5 ? MERIT : (avg >= 5 ? PASS : FAIL);
}

int main(void) {
    Student group[] = {{"Ana", {7.5, 8.0, 9.0}}, {"Bruno", {4.0, 5.5, 3.5}},
                       {"Carla", {9.5, 8.5, 9.0}}, {"Diego", {6.0, 5.0, 7.5}}};
    int n = sizeof(group) / sizeof(group[0]), counts[3] = {0};
    const char *labels[] = {"fail", "pass", "merit"};
    FILE *report = fopen("report.txt", "w");
    if (report == NULL) return 1;
    printf("%-8s %5s  %s\n", "Student", "Avg", "Result");
    for (int i = 0; i < n; i++) {
        double avg = average(&group[i]);
        Result r = result_of(avg);
        counts[r]++;  // the enum value works as an index
        printf("%-8s %5.2f  %s\n", group[i].name, avg, labels[r]);
        fprintf(report, "%s;%.2f;%s\n", group[i].name, avg, labels[r]);
    }
    fclose(report);
    printf("Merit: %d, pass: %d, fail: %d\n", counts[MERIT], counts[PASS], counts[FAIL]);
    return 0;
}
