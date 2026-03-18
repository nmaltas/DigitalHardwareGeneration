#ifndef PARAMETERS_HPP
#define PARAMETERS_HPP

#include <cstdint>
#include <vector>
#include <string>
#include <format>

using namespace std;

class Parameters
{
public:
    uint32_t M = 3; // Rows
    uint32_t N = 4; // Columns
    uint32_t T = 8; // Width [4,32]

    vector<vector<int_fast32_t>> WMatrix{
        {116, -121, 113, -125},
        {94, -107, -113, -99},
        {-116, 121, -113, 125},
    };

    vector<int_fast32_t> BMatrix{101, 83, -55};

    vector<int_fast32_t> XMatrix{-70, -17, -75, 3};

    bool ValidSpecs = true;

    string Libraries = "library IEEE;\nuse IEEE.STD_LOGIC_1164.all;\nuse ieee.numeric_std.all;\n";

    Parameters()
    {
    }

    bool Verify()
    {
        // Built-in self-verification for parameters matching matrix dimensions.
        cout << "> Verifying spec values and matrix dimensions..." << endl;
        ValidSpecs = true;

        if (M != WMatrix.size())
        {
            ValidSpecs = false;
            cout << "> Number of rows M doesn't match W Matrix row count." << endl;
        }

        try
        {
            for (int i = 0; i < M; i++)
            {
                if (N != WMatrix.at(i).size())
                {
                    ValidSpecs = false;
                    cout << format("> Number of columns N doesn't match W Matrix column count at row {}.", i) << endl;
                }
            }
        }
        catch (const out_of_range &temp)
        {
            cerr << "> Error: " << temp.what() << endl;
        }

        if (M != BMatrix.size())
        {
            ValidSpecs = false;
            cout << "> Number of rows M doesn't match B Matrix size." << endl;
        }

        if (N != XMatrix.size())
        {
            ValidSpecs = false;
            cout << "> Number of coulmns N doesn't match X Matrix size." << endl;
        }

        if (ValidSpecs)
        {
            cout << format("> All tests have passed. The system supports {}x{} operations of width {}.", M, N, T) << endl;
        }
        else
        {
            cout << "> There are issues with the given specs. The source code files cannot be generated until said issues are resolved." << endl;
        }

        return ValidSpecs;
    }
};

#endif