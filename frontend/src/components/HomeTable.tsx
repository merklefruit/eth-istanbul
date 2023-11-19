import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "./ui/button";
import Link from "next/link";

const rows = [
  {
    icon: "✨",
    address: "0x538d72dEd42A76A30f730292Da939e0577f22F57",
    totalAmount: "$250.00",
    topAssets: "ETH, DAI, CRV",
    desc: "Senior portfolio manager @ private fund",
  },
  {
    icon: "👋",
    address: "0x48EC5560bFD59b95859965cCE48cC244CFDF6b0c",
    totalAmount: "$150.00",
    topAssets: "WBTC, DOGE, LINK",
    desc: "Crypto OG since 2013",
  },
  {
    icon: "📣",
    address: "0xA2aFbEdF7E5c8bf94ee7a4f7912359104c186881",
    totalAmount: "$350.00",
    topAssets: "ETH, GEAR, CRV",
    desc: "Got lucky last bull run, looking to repeat",
  },
  {
    icon: "❌",
    address: "0x9D3de545F58C696946b4Cf2c884fcF4f7914cB53",
    totalAmount: "$450.00",
    topAssets: "GHO, SHIB, PEPE",
    desc: "Unhinged degenerate, don't follow me",
  },
  {
    icon: "❌",
    address: "0x5f9579E5Ea193D4FbdF73C19dbc71EbBD003741a",
    totalAmount: "$550.00",
    topAssets: "MARIO, LUIGI, PEACH",
    desc: "I'm a me, Mario!",
  },
  {
    icon: "📣",
    address: "0x1f9090aaE28b8a3dCeaDf281B0F12828e676c326",
    totalAmount: "$200.00",
    topAssets: "ETH, WBTC",
    desc: "Boomer investor, looking for a safe bet",
  },
  {
    icon: "📣",
    address: "0x9D3de545F58C696946b4Cf2c884fcF4f7914cB53",
    totalAmount: "$300.00",
    topAssets: "FILE, CRV, AAVE",
    desc: "The modern curious tech investor",
  },
];

export function HomeTable() {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead className="w-[70px]">Status</TableHead>
          <TableHead className="w-[380px]">Address</TableHead>
          <TableHead className="w-[250px]">Top 3 assets</TableHead>
          <TableHead className="">Description</TableHead>
          <TableHead></TableHead>
        </TableRow>
      </TableHeader>

      <TableBody>
        {rows.map((row, idx) => (
          <TableRow key={idx}>
            <TableCell className="font-medium">{row.icon}</TableCell>
            <TableCell className="font-mono">{row.address}</TableCell>
            <TableCell>{row.topAssets}</TableCell>
            <TableCell>{row.desc}</TableCell>
            <TableCell className="text-right">
              <Link href={`/invest/${row.address}`}>
                <Button className="bg-gray-800 hover:bg-gray-700">
                  Replicate This Portfolio
                </Button>
              </Link>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
