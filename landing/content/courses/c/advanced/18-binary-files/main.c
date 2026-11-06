#include <stdio.h>

typedef struct { char name[16]; int stock; double price; } Product;

int main(void) {
    Product items[] = {{"Keyboard", 14, 29.90}, {"Mouse", 40, 12.50}, {"Monitor", 6, 189.00}};
    FILE *f = fopen("products.dat", "wb");  // "b": bytes, exactly as in memory
    if (!f) { perror("products.dat"); return 1; }
    size_t written = fwrite(items, sizeof(Product), 3, f);  // 3 records at once
    fclose(f);
    printf("Wrote %zu records of %zu bytes\n", written, sizeof(Product));

    f = fopen("products.dat", "r+b");  // read and write, without truncating
    if (!f) { perror("products.dat"); return 1; }
    fseek(f, 0, SEEK_END);
    printf("File size: %ld bytes\n", ftell(f));

    Product p;
    fseek(f, 1 * sizeof(Product), SEEK_SET);  // jump straight to record 1
    if (fread(&p, sizeof p, 1, f) != 1) { fclose(f); return 1; }
    p.stock -= 5;                             // sell 5 mice
    fseek(f, 1 * sizeof(Product), SEEK_SET);  // and overwrite that record
    fwrite(&p, sizeof p, 1, f);

    rewind(f);                                // back to the start: read them all
    while (fread(&p, sizeof p, 1, f) == 1)
        printf("%-9s %3d x %7.2f\n", p.name, p.stock, p.price);
    fclose(f);
    remove("products.dat");
    return 0;
}
