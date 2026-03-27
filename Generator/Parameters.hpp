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
    uint32_t M = 3; // Rows. [2, 32]
    uint32_t N = 3; // Columns. [2, 32]
    uint32_t T = 8; // Width [4,32]

    vector<vector<int_fast32_t>> WMatrix{
        {116, -121, 113},
        {94, -107, -113},
        {-116, 121, -113}};

    vector<int_fast32_t> BMatrix{101, 83, -55};

    vector<vector<int_fast32_t>> XMatrix{
        {-70, -17, -75},  // No overflow/undeflow.
        {105, -122, -93}, // Overflow in row 2.
        {-105, 122, 93},  // Underflow in row 2.
        {118, -120, 85},  // Overflow in row 1, underflow in row 3.
        {-55, -14, -5}    // No underflow/overflow.
    };

    bool ValidSpecs = true;

    string Libraries = "library IEEE;\nuse IEEE.STD_LOGIC_1164.all;\nuse ieee.numeric_std.all;\n";

    string FolderName;

    Parameters()
    {
        ReadFile();

        if (M < 2 || M > 32)
        {
            ValidSpecs = false;
            cout << "Number of rows M out of bounds. It has to be within [2,32]." << endl;
        }

        if (N < 2 || N > 32)
        {
            ValidSpecs = false;
            cout << "Number of coluns N out of bounds. It has to be within [2,32]." << endl;
        }

        if (T < 4 || T > 32)
        {
            ValidSpecs = false;
            cout << "Number width T out of bounds. It has to be within [4,32]." << endl;
        }

        FolderName = format("{}x{}_{}b", M, N, T);
    }

    bool Verify()
    {

        if (ValidSpecs == false)
        {
            return ValidSpecs;
        }

        // Built-in self-verification for parameters matching matrix dimensions.
        cout << "> Verifying spec values and matrix dimensions..." << endl;
        ValidSpecs = true;

        // Checking W Matrix dimensions.
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

        // Checking B Matrix dimensions.
        if (M != BMatrix.size())
        {
            ValidSpecs = false;
            cout << "> Number of rows M doesn't match B Matrix size." << endl;
        }

        // Checking X Matrix dimensions.
        try
        {
            for (int i = 0; i < N; i++)
            {
                if (N != XMatrix.at(i).size())
                {
                    ValidSpecs = false;
                    cout << format("> Number of coulmns N doesn't match X Matrix column count at row {}.", i) << endl;
                }
            }
        }
        catch (const out_of_range &temp)
        {
            cerr << "> Error: " << temp.what() << endl;
        }

        // Final check.
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

private:
    bool ReadFile()
    {
        ifstream ParameterFile;
        ParameterFile.open("Parameters.csv");

        if (!ParameterFile)
        {
            cout << "No parameters file found. Proceeding with hard-coded parameters and values." << endl;
            return false;
        }

        ParameterFile.close();

        return true;
    }
};

#endif