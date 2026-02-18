#include <unistd.h>
#include <iostream>

int main()
{
    const size_t size = 256;
    char name[size];

    if (gethostname(name, size) != 0) {
        std::cerr << "Error getting hostname\n";
        return 1;
    }

    std::cout << "Hello World from " << name << std::endl;

    return 0;
}

