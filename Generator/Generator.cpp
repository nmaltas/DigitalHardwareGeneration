#include <iostream>
#include <cstdint>
#include <vector>

#include "Parameters.hpp"

using namespace std;

void PrintTables(const Parameters &Specs);

int main()
{

    Parameters Specs;

    PrintTables(Specs);

    cout << "Hey!!" << endl;
    return 0;
}

void PrintTables(const Parameters &Specs)
{
    // Printing W Matrix
    cout << "W is :" << endl;
    for (int i = 0; i < Specs.M; i++)
    {
        cout << "| ";
        for (int j = 0; j < Specs.N; j++)
        {
            cout << Specs.WMatrix.at(i).at(j);
            if (j == (Specs.N - 1))
            {
                cout << "\t|" << endl;
            }
            else
            {
                cout << ", ";
            }
        }
    }

    // Printing X Matrix
    cout << "X is :" << endl;
    cout << "| ";
    for (int i = 0; i < Specs.N; i++)
    {
        cout << Specs.XMatrix.at(i);

        if (i == (Specs.N - 1))
        {
            cout << " |" << endl;
        }
        else
        {
            cout << ", ";
        }
    }

    // Printing B Matrix
    cout << "B is :" << endl;
    cout << "| ";
    for (int i = 0; i < Specs.M; i++)
    {
        cout << Specs.BMatrix.at(i);

        if (i == (Specs.M - 1))
        {
            cout << " |" << endl;
        }
        else
        {
            cout << ", ";
        }
    }

    return;
}