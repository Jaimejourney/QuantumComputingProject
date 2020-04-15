using System.Threading.Tasks;
using Microsoft.Quantum.Simulation.Simulators;
using System;

namespace CounterFeitCoinAlgorithm
{
    class Driver
    {
        static async Task Main(string[] args)
        {
            using var qsim = new QuantumSimulator();

            var result = await CounterfeitCoin_Main.Run(qsim);
            Console.WriteLine($"{result}");


            Console.WriteLine("\n\nPress any key to continue...\n\n");
            Console.ReadKey();

        }
    }
}